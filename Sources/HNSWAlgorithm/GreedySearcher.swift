import PriorityHeapModule

/// A searcher that uses a greedy strategy to find optimal items according to a specified priority metric.
///
/// This approach is well-suited for small world networks, where the inherent clustering and short path lengths allow
/// for efficient greedy traversal to quickly identify locally optimal solutions that are often globally optimal as well.
/// Additionally, its design accommodates hierarchical searches, enabling phased exploration with varying neighbor sets
/// at each level, making it ideal for multi-layered structures.
public struct GreedySearcher<Key: Hashable, PriorityKey: Identifiable & Prioritizable> where PriorityKey.ID == Key {
    /// The metric guiding the prioritization of items.
    public let prioritize: (Key) -> PriorityKey
    /// The heap of candidates deemed optimal by the metric.
    public private(set) var optimal: PriorityHeap<PriorityKey>
    
    /// Creates a new searcher with an initial set of items, using a priority metric to guide the search towards optimality.
    ///
    /// - Parameters:
    ///   - initial: The initial set of items to be considered and evaluated.
    ///   - metric: The metric used to prioritize and guide the search process.
    public init(initial: [Key], prioritize: @escaping (Key) -> PriorityKey) {
        self.prioritize = prioritize
        self.optimal = .init(initial.lazy.map(prioritize))
    }
    
    /// Updates the searcher's state by exploring neighboring items and refining the set of optimal candidates.
    ///
    /// Expands the search from the current best candidates, using the navigator to explore adjacent items within
    /// the specified capacity. The search halts when no neighbors improve upon the existing optimal set, ensuring
    /// focus on the most promising candidates as determined by the metric.
    ///
    /// - Parameters:
    ///   - navigator: An entity that provides neighboring items to consider.
    ///   - capacity: The maximum number of candidates to maintain.
    ///
    /// - Precondition: The capacity must not be less than the current number of optimal candidates.
    public mutating func refine(capacity: Int, neighborhood: (Key) -> [Key], record: ((from: Key, to: Key)) -> Void = { _ in }) {
        precondition(optimal.count <= capacity, "Capacity limit must not be lesser than current count of optimal candidates.")
        var considered: Set<Key> = .init(optimal.unordered.lazy.map(\.id))
        var frontier: PriorityHeap<PriorityKey>
        (frontier, optimal) = (optimal, [])
        
        while let unprocessed = frontier.popMax() {
            optimal.insert(unprocessed)
            for neighbor in neighborhood(unprocessed.id) {
                guard considered.insert(neighbor).inserted else { continue }
                let neighbor = prioritize(neighbor)
                if optimal.count + frontier.count >= capacity {
                    guard neighbor.priority > PriorityHeap.min(optimal, frontier)!.priority else { continue }
                    PriorityHeap.withLesserHeap(&optimal, &frontier, ifEqual: .first) { _ = $0.removeMin() }
                }
                frontier.insert(neighbor)
                record((from: unprocessed.id, to: neighbor.id))
            }
        }
    }
}
