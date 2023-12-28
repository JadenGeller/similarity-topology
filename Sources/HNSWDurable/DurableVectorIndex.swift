import CoreLMDB
import SimilarityMetric
import HNSWAlgorithm
import CoreLMDBCoders

public struct DurableVectorIndex<Metric: SimilarityMetric, VectorComponent: UnsafeMemoryLayoutStorableFloat> where Metric.Vector == [VectorComponent] {
    @usableFromInline
    internal let graph: DurableGraph
    
    @usableFromInline
    internal let registry: DurableVectorRegistry<VectorComponent>
    
    @usableFromInline
    internal let metric: Metric
    
    @usableFromInline
    internal let config: Config

    @inlinable
    public init(namespace: String, metric: Metric, config: Config, in transaction: Transaction) throws {
        graph = try DurableGraph(namespace: "\(namespace)/graph", in: transaction)
        registry = try DurableVectorRegistry(namespace: "\(namespace)/vector", in: transaction)
        self.metric = metric
        self.config = config
    }
    
    @inlinable @inline(__always)
    public static var countNamedDBs: Int { DurableGraph.countNamedDBs + DurableVectorRegistry<VectorComponent>.countNamedDBs }
        
    public struct Accessor {
        public let graph: DurableGraph.Accessor

        public let registry: DurableVectorRegistry<VectorComponent>.Accessor

        @usableFromInline
        internal let metric: Metric
        
        @usableFromInline
        internal let config: Config

        @inlinable
        public init(for store: DurableVectorIndex, in transaction: Transaction) throws {
            graph = try DurableGraph.Accessor(for: store.graph, in: transaction)
            registry = try DurableVectorRegistry.Accessor(for: store.registry, in: transaction)
            self.metric = store.metric
            self.config = store.config
        }
        
        @inlinable
        public var indexManager: IndexManager<DurableGraph.Accessor, Metric> {
            .init(
                graph: graph,
                metric: metric,
                vector: registry.vector,
                config: config
            )
        }
        
        @inlinable
        public func find(near query: Metric.Vector, limit: Int) throws -> some Sequence<NearbyVector<DurableVectorRegistry.ForeignKey, Metric.Vector, Metric.Similarity>> {
            try indexManager.find(near: query, limit: limit).map({ $0.mapID(registry.toForeignKey) })
        }
        
        @inlinable
        public func insert(_ vector: Metric.Vector, forKey key: DurableVectorRegistry.ForeignKey, using generator: inout some RandomNumberGenerator) {
            let indexKey = registry.register(vector, forForeignKey: key)
            indexManager.insert(vector, forKey: indexKey, using: &generator)
        }
    }
    
    public func dropDatabase(keepVectors: Bool, in transaction: Transaction) throws {
        try graph.dropDatabase(in: transaction)
        if !keepVectors {
            try registry.dropDatabase(in: transaction)
        }
    }
}
