import HNSWAlgorithm
import SimilarityMetric
import PriorityHeapModule

public struct EphemeralVectorIndex<Key: BinaryInteger, Level: BinaryInteger, Metric: SimilarityMetric, Metadata> {
    private var nextKey: Key = 0
    public private(set) var vectors: [Metric.Vector] = []
    
    public typealias Graph = EphemeralGraph<Key, Level>
    
    public var graph = Graph()
    public var metric: Metric
    public var config: Config

    public init(metric: Metric, config: Config) {
        self.metric = metric
        self.config = config
    }
    
    internal var manager: IndexManager<Graph, Metric> {
        .init(graph: graph, metric: metric, vector: { vectors[Int($0)] }, config: config)
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
