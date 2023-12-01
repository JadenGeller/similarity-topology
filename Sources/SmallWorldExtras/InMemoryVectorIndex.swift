import SmallWorld
import PriorityHeapModule

public struct InMemoryVectorIndex<Key: BinaryInteger, Level: BinaryInteger, Metric: SimilarityMetric, Metadata> {
    private var nextKey: Key = 0
    public private(set) var vectors: [Metric.Vector] = []
    
    public typealias Graph = InMemoryGraphStorage<Key, Level>
    
    public var graph = Graph()
    public var metric: Metric
    public var params: AlgorithmParameters

    public init(metric: Metric, params: AlgorithmParameters) {
        self.metric = metric
        self.params = params
    }
    
    internal var manager: GraphManager<Graph, Metric> {
        .init(graph: graph, metric: metric, vector: { vectors[Int($0)] }, params: params)
    }

    public typealias Neighbor = NearbyVector<Graph.Key, Metric.Vector, Metric.Similarity>
    
    public func find(near query: Metric.Vector, limit: Int) throws -> some Sequence<Neighbor> {
        try manager.find(near: query, limit: limit)
    }

    public mutating func insert(_ vector: Metric.Vector, using generator: inout some RandomNumberGenerator) -> Key {
        vectors.append(vector)
        let key = nextKey
        nextKey += 1
        
        manager.insert(vector, forKey: key, using: &generator)
        return key
    }

}
