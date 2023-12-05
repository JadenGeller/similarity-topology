import CoreLMDB
import HNSW

public struct DurableVectorIndex<Metric: SimilarityMetric> where Metric.Vector == [Float32] {
    @usableFromInline
    internal let graph: DurableGraph
    
    @usableFromInline
    internal let registry: DurableVectorRegistry
    
    @usableFromInline
    internal let metric: Metric
    
    @usableFromInline
    internal let params: AlgorithmParameters

    @inlinable
    public init(namespace: String, metric: Metric, params: AlgorithmParameters, in transaction: Transaction) throws {
        graph = try DurableGraph(namespace: "\(namespace)/graph", in: transaction)
        registry = try DurableVectorRegistry(namespace: "\(namespace)/vector", in: transaction)
        self.metric = metric
        self.params = params
    }
    
    public typealias Accessor = IndexManager<DurableGraph.Accessor, Metric>
}
extension IndexManager where Graph == DurableGraph.Accessor, Metric.Vector == [Float32] {
    @inlinable
    public init(for index: DurableVectorIndex<Metric>, in transaction: Transaction) throws {
        self.init(
            graph: try DurableGraph.Accessor(for: index.graph, in: transaction),
            metric: index.metric,
            vector: try DurableVectorRegistry.Accessor(for: index.registry, in: transaction).vector,
            params: index.params
        )
    }
}
