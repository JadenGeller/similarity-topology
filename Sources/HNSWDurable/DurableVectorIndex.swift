import CoreLMDB
import SimilarityMetric
import HNSWAlgorithm

public struct DurableVectorIndex<Metric: SimilarityMetric> where Metric.Vector == [Float32] {
    @usableFromInline
    internal let graph: DurableGraph
    
    @usableFromInline
    internal let registry: DurableVectorRegistry
    
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
    public static var countNamedDBs: Int { DurableGraph.countNamedDBs + DurableVectorRegistry.countNamedDBs }
        
    public struct Accessor {
        @usableFromInline
        internal var graphAccessor: DurableGraph.Accessor

        @usableFromInline
        internal var vectorRegistryAccessor: DurableVectorRegistry.Accessor

        @usableFromInline
        internal let metric: Metric
        
        @usableFromInline
        internal let config: Config

        @inlinable
        public init(for store: DurableVectorIndex, in transaction: Transaction) throws {
            graphAccessor = try DurableGraph.Accessor(for: store.graph, in: transaction)
            vectorRegistryAccessor = try DurableVectorRegistry.Accessor(for: store.registry, in: transaction)
            self.metric = store.metric
            self.config = store.config
        }
        
        @inlinable
        internal var indexManager: IndexManager<DurableGraph.Accessor, Metric> {
            .init(
                graph: graphAccessor,
                metric: metric,
                vector: vectorRegistryAccessor.vector,
                config: config
            )
        }
        
        @inlinable
        public func find(near query: Metric.Vector, limit: Int) throws -> some Sequence<NearbyVector<DurableVectorRegistry.ForeignKey, Metric.Vector, Metric.Similarity>> {
            try indexManager.find(near: query, limit: limit).map({ $0.mapID(vectorRegistryAccessor.toForeignKey) })
        }

        @inlinable
        public mutating func insert(_ vector: Metric.Vector, forKey key: DurableVectorRegistry.ForeignKey, using generator: inout some RandomNumberGenerator) {
            let indexKey = vectorRegistryAccessor.register(vector, forForeignKey: key)
            indexManager.insert(vector, forKey: indexKey, using: &generator)
        }
    }
}
