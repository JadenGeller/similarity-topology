import PriorityHeapModule

// TODO: Allow rebuilding the index
public protocol VectorIndex {
    associatedtype Registrar: VectorRegistrar where Registrar.Key == Graph.Key, Registrar.Vector == Metric.Vector
    associatedtype Graph: GraphStorage
    associatedtype Metric: SimilarityMetric

    typealias Manager = GraphManager<Graph, Metric>
    
    var registrar: Registrar { get }
    var graph: Graph { get }
    var metric: Metric { get }
    var params: AlgorithmParameters { get }
}

extension VectorIndex {
    internal var manager: Manager {
        .init(graph: graph, metric: metric, vector: registrar.vector, params: params)
    }
}

extension VectorIndex {
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

public struct InMemoryVectorIndex<Key: BinaryInteger, Level: BinaryInteger, Metric: SimilarityMetric, Metadata>: VectorIndex {
    public var registrar = InMemoryVectorRegistrar<Key, Metric.Vector, Metadata>()
    public var graph = InMemoryGraphStorage<Key, Level>()
    public var metric: Metric
    public var params: AlgorithmParameters

    public init(metric: Metric, params: AlgorithmParameters) {
        self.metric = metric
        self.params = params
    }
}
