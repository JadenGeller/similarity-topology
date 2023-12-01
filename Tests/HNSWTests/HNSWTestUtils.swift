import HNSW
import GameplayKit
import PriorityHeapModule

struct AdjacencyTree<Element> {
    var vertex: Element
    var children: [Self]
    
    init(_ vertex: Element, _ children: [Self] = []) {
        self.vertex = vertex
        self.children = children
    }
    
    struct Index: Hashable {
        var address: [Int]
        
        var parent: Self? {
            guard !address.isEmpty else { return nil }
            return .init(address: Array(address.dropFirst()))
        }
        
        static var root: Index {
            .init(address: [])
        }
    }
    
    subscript(index: Index) -> Element {
        guard let first = index.address.first else { return vertex }
        return children[first][.init(address: Array(index.address.dropFirst()))]
    }
    
    func children(of index: Index) -> [Index] {
        guard let first = index.address.first else { return children.indices.map { Index(address: [$0]) } }
        return children[first].children(of: .init(address: Array(index.address.dropFirst()))).map {
            .init(address: [first] + $0.address)
        }
    }
    
    func neighborhood(around index: Index) -> [Index] {
        children(of: index) + (index.parent.map { [$0] } ?? [])
    }
}

extension AdjacencyTree {
    init?(line elements: [Element]) {
        self.init(line: elements[...])
    }
    init?(line elements: [Element].SubSequence) {
        guard let first = elements.first else { return nil }
        vertex = first
        children = AdjacencyTree(line: elements[elements.index(after: elements.startIndex)...]).map { [$0] } ?? []
    }
}

extension AdjacencyTree where Element: Comparable {
    struct PriorityIndex: Identifiable, Prioritizable {
        var id: Index
        var priority: Element
    }
    func priorityIndex(for index: Index) -> PriorityIndex {
        .init(id: index, priority: self[index])
    }
}
