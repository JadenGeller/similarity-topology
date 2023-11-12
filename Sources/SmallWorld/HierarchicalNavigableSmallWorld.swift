import PriorityHeapModule
import PriorityHeapAlgorithms
import RealModule

public struct HierarchicalNavigableSmallWorld<Graph: HierarchicalGraphStorage, Metric: SimilarityMetric> {
    var graph: Graph
    var metric: Metric
    var load: (Graph.VertexID) -> Metric.Item

    public struct Config {
        var levelGenerationScale: Double
        var constructionSearchSize: Int
        var maxNeighborsPerLayer: Int
        var maxNeighborsLayer0: Int
        var crowdToDensify: Bool
        
        public init(levelGenerationScale: Double, constructionSearchSize: Int, maxNeighborsPerLayer: Int, maxNeighborsLayer0: Int, crowdToDensify: Bool) {
            self.levelGenerationScale = levelGenerationScale
            self.constructionSearchSize = constructionSearchSize
            self.maxNeighborsPerLayer = maxNeighborsPerLayer
            self.maxNeighborsLayer0 = maxNeighborsLayer0
            self.crowdToDensify = crowdToDensify
        }
    }
    var config: Config
    
    public init(graph: Graph, metric: Metric, load: @escaping (Graph.VertexID) -> Metric.Item, config: Config) {
        self.graph = graph
        self.metric = metric
        self.load = load
        self.config = config
    }
    
    public struct SearchItem: Prioritized {
        public var item: Graph.VertexID
        public var data: Metric.Item
        public var priority: Metric.Similarity
    }
    
    private func prioritize(_ vertex: Graph.VertexID, query: Metric.Item) -> SearchItem {
        let data = load(vertex)
        return SearchItem(item: vertex, data: data, priority: metric.similarity(between: query, data))
    }
    
    private func searcher(for query: Metric.Item) -> GreedySearcher<Graph.VertexID, SearchItem> {
        GreedySearcher(from: graph.entry.map { [$0] } ?? []) { vertex in
            prioritize(vertex, query: query)
        }
    }
    
    // TODO: Should we return the similarity? Probably!
    public func neighborhood(around query: Metric.Item, size: Int) throws -> some Sequence<SearchItem> {
        var searcher = searcher(for: query)
        for layer in graph.layers {
            let limit = layer.level == 0 ? size : 1
            searcher.refine(using: layer, limit: limit)
        }
        return searcher.optimal.descending()
    }
    
    func insertionLevel(using generator: inout some RandomNumberGenerator, scale: Double) -> Int {
        Int(-.log(.random(in: 0..<1, using: &generator)) * scale)
    }
    
    private func pickDiverseNeighbors(
        fromUncheckedDescending candidates: some Sequence<SearchItem>,
        limit: Int,
        dense: Bool
    ) -> [SearchItem] {
        // TODO: Clean this up and maybe share a buffer for both of these, adding from opposite ends
        var bridging: [SearchItem] = []
        var crowding: [SearchItem] = []
        for candidate in candidates {
            if bridging.contains(where: { metric.similarity(between: $0.data, candidate.data) > candidate.priority }) {
                guard bridging.count + crowding.count < limit else { continue }
                crowding.append(candidate)
            } else {
                if bridging.count + crowding.count == limit {
                    guard !crowding.isEmpty else { break /* fully out of space! */ }
                    crowding.removeLast()
                }
                bridging.append(candidate)
            }
        }
        assert(bridging.count + crowding.count <= limit)
        return bridging + crowding
    }
    
    public func insert(_ newElement: Metric.Item, as newVertex: Graph.VertexID, using generator: inout some RandomNumberGenerator) {
        var searcher = searcher(for: newElement) // must create before inserting
        
        let insertionLevel = insertionLevel(using: &generator, scale: config.levelGenerationScale)
        graph.insert(newVertex, on: insertionLevel)
        for layer in graph.layers {
            guard layer.level <= insertionLevel else {
                searcher.refine(using: layer, limit: 1)
                continue
            }
            searcher.refine(using: layer, limit: config.constructionSearchSize)

            let maxNeighbors = layer.level == 0 ? config.maxNeighborsLayer0 : config.maxNeighborsPerLayer
            let newNeighbors = pickDiverseNeighbors(
                fromUncheckedDescending: searcher.optimal.descending(),
                limit: maxNeighbors,
                dense: config.crowdToDensify
            )
            layer.updateNeighborhood(around: newVertex, with: newNeighbors.map(\.item))
            
            for node in newNeighbors {
                let neighbors = Array(layer.neighborhood(around: node.item))
                guard neighbors.count > maxNeighbors else { continue }
                layer.updateNeighborhood(around: node.item, with: pickDiverseNeighbors(
                    fromUncheckedDescending: neighbors
                        .map { prioritize($0, query: node.data) }
                        .sorted(by: { $0.priority > $1.priority }),
                    limit: maxNeighbors,
                    dense: config.crowdToDensify
                ).map(\.item))
            }
        }
    }
}
