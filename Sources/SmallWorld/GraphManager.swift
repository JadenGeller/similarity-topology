import PriorityHeapModule
import PriorityHeapAlgorithms
import RealModule

public struct GraphManager<Graph: GraphStorage, Metric: SimilarityMetric> {
    public var graph: Graph
    public var metric: Metric
    public var vector: (Graph.Key) -> Metric.Vector
    public var params: AlgorithmParameters
    
    public init(graph: Graph, metric: Metric, vector: @escaping (Graph.Key) -> Metric.Vector, params: AlgorithmParameters) {
        self.graph = graph
        self.metric = metric
        self.vector = vector
        self.params = params
    }
}

extension GraphManager {
    public typealias Candidate = NearbyVector<Graph.Key, Metric.Vector, Metric.Similarity, Void>
    
    private func prioritize(_ id: Graph.Key, relativeTo reference: Metric.Vector) -> Candidate {
        let vector = vector(id)
        return .init(id: id, vector: vector, priority: metric.similarity(between: reference, vector))
    }
    
    private func searcher(for query: Metric.Vector) -> GreedySearcher<Graph.Key, Candidate> {
        .init(initial: graph.entry.map { [$0.key] } ?? []) { vertex in
            prioritize(vertex, relativeTo: query)
        }
    }
}

extension GraphManager {
    public func find(near query: Metric.Vector, limit: Int) throws -> some Sequence<Candidate> {
        var searcher = searcher(for: query)
        for level in graph.descendingLevels() {
            searcher.refine(capacity: 1) { graph.neighborhood(around: $0, on: level) }
        }
        searcher.refine(capacity: limit) { graph.neighborhood(around: $0, on: 0) }
        return searcher.optimal.descending()
    }
}

extension GraphManager {
    private func randomInsertionLevel(using generator: inout some RandomNumberGenerator) -> Graph.Level {
        .init(-.log(.random(in: 0..<1, using: &generator)) * params.insertionLevelGenerationLogScale)
    }
    
    // TODO: Can this be optimized for the case where limit is 1 greater than the number of candidates?
    private func diverseNeighborhood(from candidates: DescendingSequence<Candidate>, maxNeighborhoodSize: Int) -> [Candidate] {
        // TODO: Clean this up and maybe share a buffer for both of these, adding from opposite ends
        // TODO: Implement the extended neighbor params option
        var bridging: [Candidate] = []
        var crowding: [Candidate] = []
        for candidate in candidates {
            if bridging.contains(where: { metric.similarity(between: $0.vector, candidate.vector) > candidate.priority }) {
                guard bridging.count + crowding.count < maxNeighborhoodSize else { continue }
                crowding.append(candidate)
            } else {
                if bridging.count + crowding.count == maxNeighborhoodSize {
                    guard !crowding.isEmpty else { break /* fully out of space! */ }
                    crowding.removeLast()
                }
                bridging.append(candidate)
            }
        }
        assert(bridging.count + crowding.count <= maxNeighborhoodSize)
        switch params.neighborhoodPreference {
        case .preferDensity: return bridging + crowding
        case .preferEfficiency: return bridging
        }
    }
    
    private func updateExtendedNeighborhood(forKey id: Graph.Key, on level: Graph.Level, from candidates: DescendingSequence<Candidate>, maxNeighborhoodSize: Int) {
        let immediateNeighborhood = diverseNeighborhood(from: candidates, maxNeighborhoodSize: params.maxNeighborhoodSizeCreate)
        graph.replaceNeighborhood(around: id, on: level, with: immediateNeighborhood.map(\.id))
        
        for immediateNeighbor in immediateNeighborhood {
            let extendedNeighborhood = graph.neighborhood(around: immediateNeighbor.id, on: level)
            guard extendedNeighborhood.count > maxNeighborhoodSize else { continue }
            graph.replaceNeighborhood(around: immediateNeighbor.id, on: level, with: diverseNeighborhood(
                from: PriorityHeap(extendedNeighborhood.map { prioritize($0, relativeTo: immediateNeighbor.vector) }).descending(),
                maxNeighborhoodSize: maxNeighborhoodSize
            ).map(\.id))
        }
    }
    
    public func insert(_ vector: Metric.Vector, forKey id: Graph.Key, using generator: inout some RandomNumberGenerator) {
        let insertionLevel = randomInsertionLevel(using: &generator)
        
        var searcher = searcher(for: vector)
        for level in graph.descendingLevels(through: insertionLevel + 1) {
            searcher.refine(capacity: 1) { graph.neighborhood(around: $0, on: level) }
        }
        for level in graph.descendingLevels(from: insertionLevel, through: 1) {
            searcher.refine(capacity: params.constructionSearchCapacity) { graph.neighborhood(around: $0, on: level) }
            updateExtendedNeighborhood(forKey: id, on: level, from: searcher.optimal.descending(), maxNeighborhoodSize: params.maxNeighborhoodSizeLevelN)
        }
        searcher.refine(capacity: params.constructionSearchCapacity) { graph.neighborhood(around: $0, on: 0) }
        updateExtendedNeighborhood(forKey: id, on: 0, from: searcher.optimal.descending(), maxNeighborhoodSize: params.maxNeighborhoodSizeLevel0)
        
        graph.register(id, on: insertionLevel)
    }
}
