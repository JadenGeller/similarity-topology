public protocol HierarchicalGraphStorage<VertexID>: AnyObject {
    associatedtype VertexID: Hashable
    associatedtype LayerSequence: Sequence where LayerSequence.Element: HierarchicalGraphStorageLayer<VertexID>
    
    var entry: VertexID? { get }
    var layers: LayerSequence { get }
    func insert(_ vertex: VertexID, on level: Int)
}
public protocol HierarchicalGraphStorageLayer<VertexID>: AnyObject, AdjacencyNavigator {
    var level: Int { get }
    func updateNeighborhood(around vertex: VertexID, with newNeighborhood: [VertexID])
}

public class InMemoryHierarchicalGraphStorage<VertexID: Hashable>: HierarchicalGraphStorage {
    public class Layer: HierarchicalGraphStorageLayer {
        public let level: Int
        public private(set) var neighborhood: [VertexID: Set<VertexID>]
        
        fileprivate init(level: Int, neighborhood: [VertexID: Set<VertexID>]) {
            self.level = level
            self.neighborhood = neighborhood
        }
        
        public func neighborhood(around vertex: VertexID) -> [VertexID] {
            Array(neighborhood[vertex, default: []])
        }
        public func updateNeighborhood(around vertex: VertexID, with newNeighborhood: [VertexID]) {
            neighborhood[vertex, default: []] = Set(newNeighborhood)
            for neighbor in newNeighborhood {
                neighborhood[neighbor, default: []].insert(vertex)
            }
        }
    }
    
    public private(set) var entry: VertexID? = nil
    public private(set) var layers: [Layer] = []
    
    public init() { }
    
    // TODO: use binary search to find more efficiently
    private func addLayerIfNeeded(on level: Int) -> Bool {
        var previous: [VertexID: Set<VertexID>] = [:]
        for (index, layer) in layers.enumerated() {
            defer { previous = layer.neighborhood }
            guard layer.level != level else { return false /* not needed */ }
            guard layer.level < level else { continue /* not there yet */ }
            // FIXME: This clones layer above. I think that's equivalent to eagerly adding things.
            // It doesn't super seem like something that InMemory version should be figuring out tho
            layers.insert(.init(level: level, neighborhood: previous), at: index)
            return true
        }
        layers.append(.init(level: level, neighborhood: layers.last?.neighborhood ?? [:]))
        return true
    }
    
    // FIXME: We need to not include the newly inserted layer in the search if its on the top...!
    public func insert(_ vertex: VertexID, on level: Int) {
        if level > (layers.first?.level ?? -1) {
            entry = vertex
        }
        addLayerIfNeeded(on: level)
    }
}
