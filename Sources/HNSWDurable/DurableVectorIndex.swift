import CoreLMDB
import HNSW

public final class VectorIndex<Metric: SimilarityMetric> where Metric.Vector == [Float32] {
    internal let graph: DurableGraph
    internal let registry: DurableVectorRegistry
    internal let metric: Metric
    internal let params: AlgorithmParameters

    public init(namespace: String, metric: Metric, params: AlgorithmParameters, in transaction: Transaction) throws {
        graph = try DurableGraph(namespace: "\(namespace)/graph", in: transaction)
        registry = try DurableVectorRegistry(namespace: "\(namespace)/vector", in: transaction)
        self.metric = metric
        self.params = params
    }
    
    public typealias Accessor = IndexManager<DurableGraph.Accessor, Metric>
}
extension IndexManager where Graph == DurableGraph.Accessor, Metric.Vector == [Float32] {
    public init(for index: VectorIndex<Metric>, in transaction: Transaction) throws {
        self.init(
            graph: try DurableGraph.Accessor(for: index.graph, in: transaction),
            metric: index.metric,
            vector: try DurableVectorRegistry.Accessor(for: index.registry, in: transaction).vector,
            params: index.params
        )
    }
}
