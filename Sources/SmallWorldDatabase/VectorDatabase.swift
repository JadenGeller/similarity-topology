import SmallWorld
import CoreLMDB
import CoreLMDBCoders
import System

struct DurableVectorIndex<Metric: SimilarityMetric> where Metric.Vector: VectorProtocol {
    var registrarCursor: RawCursor
    var graphCursor: RawCursor
    var metric: Metric
    var params: AlgorithmParameters

    typealias Registrar = DurableVectorRegistrar<Metric.Vector, StringByteCoder>
    var registrar: Registrar {
        .init(cursor: registrarCursor, metadataCoder: .init())
    }
    
    typealias Graph = DurableGraphStorage
    typealias Manager = GraphManager<Graph, Metric>
    var manager: Manager {
        .init(graph: .init(cursor: graphCursor), metric: metric, vector: registrar.vector, params: params)
    }

    public typealias Neighbor = NearbyVector<Graph.Key, Metric.Vector, Metric.Similarity, Registrar.Metadata>

    public func find(near query: Registrar.Vector, limit: Int) throws -> some Sequence<Neighbor> {
        try manager.find(near: query, limit: limit).map {
            $0.withMetadata(registrar.metadata(forKey: $0.id))
        }
    }

    public func insert(_ vector: Registrar.Vector, with metadata: Registrar.Metadata, using generator: inout some RandomNumberGenerator) {
        manager.insert(vector, forKey: registrar.register(vector, with: metadata), using: &generator)
    }
}

class VectorDatabase<Metric: SimilarityMetric> {
    var environment: Environment
    var registrarDatabase: RawDatabase
    var graphDatabase: RawDatabase
    
    var metric: Metric
    var params: AlgorithmParameters
    
    init(path: FilePath, metric: Metric, params: AlgorithmParameters) throws {
        environment = try .init()
        try environment.open(path: path)
        (registrarDatabase, graphDatabase) = try environment.withTransaction(.write) { transaction in
            try (
                Database.open("registrar", schema: .init(keyCoder: RawByteCoder(), valueCoder: RawByteCoder()), in: transaction),
                Database.open("graph", schema: .init(keyCoder: RawByteCoder(), valueCoder: RawByteCoder()), in: transaction)
            )
        }
        self.metric = metric
        self.params = params
    }

    func withTransaction<Result>(_ kind: Transaction.Kind, block: (DurableVectorIndex<Metric>) throws -> Result) throws -> Result {
        try environment.withTransaction(kind) { transaction in
            try transaction.withCursor(for: registrarDatabase) { registrarCursor in
                try transaction.withCursor(for: graphDatabase) { graphCursor in
                    try block(DurableVectorIndex(
                        registrarCursor: registrarCursor,
                        graphCursor: graphCursor,
                        metric: metric,
                        params: params
                    ))
                }
            }
        }
    }
}
