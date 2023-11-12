protocol HierarchicalGraphStorage<Vertex>: AnyObject {
    associatedtype Vertex: Identifiable
    associatedtype LayerSequence: Sequence where LayerSequence.Element: HierarchicalGraphStorageLayer<Vertex>
    
    var entry: Vertex? { get }
    var layers: LayerSequence { get }
    func insert(on level: Int) -> Vertex
}
protocol HierarchicalGraphStorageLayer<Vertex>: AnyObject, AdjacencyNavigator {
    var level: Int { get }
    func updateNeighborhood(around vertex: Vertex, with newNeighborhood: [Vertex])
}

class InMemoryHierarchicalGraphStorage<Allocator: IteratorProtocol>: HierarchicalGraphStorage where Allocator.Element: Identifiable & Hashable {
    typealias Vertex = Allocator.Element
    
    class Layer: HierarchicalGraphStorageLayer {
        var level: Int
        var neighborhood: [Vertex.ID: Set<Vertex>] = [:]
        
        init(level: Int) {
            self.level = level
        }
        
        func neighborhood(around vertex: Vertex) -> [Vertex] {
            Array(neighborhood[vertex.id, default: []])
        }
        func updateNeighborhood(around vertex: Vertex, with newNeighborhood: [Vertex]) {
            neighborhood[vertex.id, default: []].formUnion(newNeighborhood)
        }
    }
    
    var allocator: Allocator
    var entry: Vertex? = nil
    var layers: [Layer] = []
    
    init(allocator: Allocator) {
        self.allocator = allocator
    }
    
    // TODO: use binary search to find more efficiently
    func addLayerIfNeeded(on level: Int) {
        for (index, layer) in layers.enumerated() {
            guard layer.level != level else { return /* not needed */ }
            guard layer.level < level else { continue /* not there yet */ }
            return layers.insert(.init(level: level), at: index)
        }
        layers.append(.init(level: level))
    }
    
    func insert(on level: Int) -> Vertex {
        guard let vertex = allocator.next() else {
            preconditionFailure("vertex allocation failed")
        }
        if level > (layers.first?.level ?? -1) {
            entry = vertex
        }
        addLayerIfNeeded(on: level)
        return vertex
    }
}
