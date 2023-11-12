import SmallWorld
import GameplayKit

struct AdjacencyTree<Element>: AdjacencyNavigator {
    var vertex: Element
    var children: [Self]
    
    init(_ vertex: Element, _ children: [Self] = []) {
        self.vertex = vertex
        self.children = children
    }
    
    struct VertexID: Hashable {
        var address: [Int]
        
        var parent: Self? {
            guard !address.isEmpty else { return nil }
            return .init(address: Array(address.dropFirst()))
        }
        
        static var rootID: VertexID {
            .init(address: [])
        }
    }
    
    subscript(vertexID: VertexID) -> Element {
        guard let first = vertexID.address.first else { return vertex }
        return children[first][.init(address: Array(vertexID.address.dropFirst()))]
    }
    
    func children(of vertexID: VertexID) -> [VertexID] {
        guard let first = vertexID.address.first else { return children.indices.map { VertexID(address: [$0]) } }
        return children[first].children(of: .init(address: Array(vertexID.address.dropFirst()))).map {
            .init(address: [first] + $0.address)
        }
    }
    
    func neighborhood(around vertexID: VertexID) -> some Sequence<VertexID> {
        children(of: vertexID) + (vertexID.parent.map { [$0] } ?? [])
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
    struct PriorityVertex: Prioritized {
        var item: VertexID
        var priority: Element
    }
    func priorityVertex(for vertexID: VertexID) -> PriorityVertex {
        .init(item: vertexID, priority: self[vertexID])
    }
}

struct DeterministicRandomNumberGenerator: RandomNumberGenerator {
    private let randomSource: GKMersenneTwisterRandomSource

    init(seed: UInt64) {
        randomSource = GKMersenneTwisterRandomSource(seed: seed)
    }

    mutating func next() -> UInt64 {
        let upperBits = UInt64(UInt32(bitPattern: Int32(randomSource.nextInt()))) << 32
        let lowerBits = UInt64(UInt32(bitPattern: Int32(randomSource.nextInt())))
        return upperBits | lowerBits
    }
}

struct RandomGraph {
    let metric = CartesianDistanceMetric()
    let graphStorage: InMemoryHierarchicalGraphStorage<Int> = .init()
    var vectorStorage: [Int: CGPoint] = [:]
    var idAllocator = (0...).makeIterator()

    var hnsw: HierarchicalNavigableSmallWorld<InMemoryHierarchicalGraphStorage<Int>, CartesianDistanceMetric> {
        .init(
            graph: graphStorage,
            metric: metric,
            load: { vectorStorage[$0]! },
            config: .init(
                levelGenerationScale: 1.0,
                constructionSearchSize: 60,
                maxNeighborsPerLayer: 20,
                maxNeighborsLayer0: 50,
                crowdToDensify: true
            )
        )
    }
    
    var hnswRNG = DeterministicRandomNumberGenerator(seed: 0)
    mutating func insertRandomData(count: Int) {
        for _ in 0..<count {
            let vector = randomData()
            let id = idAllocator.next()!
            vectorStorage[id] = vector
            hnsw.insert(vector, as: id, using: &hnswRNG)
        }
    }
    
    var sampleRNG = DeterministicRandomNumberGenerator(seed: 1)
    mutating func randomData() -> CGPoint {
        CGPoint(
            x: .random(in: (0)...(100), using: &sampleRNG),
            y: .random(in: (0)...(100), using: &sampleRNG)
        )
    }
    
    func findExact(around query: CGPoint) -> [(key: Int, value: CGPoint)] {
        Array(vectorStorage.sorted(by: { metric.similarity(between: query, $0.value) > metric.similarity(between: query, $1.value) }).prefix(10))
    }
}

struct CartesianDistanceMetric: SimilarityMetric {
    func similarity(between someItem: CGPoint, _ otherItem: CGPoint) -> Double {
        let dx = someItem.x - otherItem.x
        let dy = someItem.y - otherItem.y
        return -(dx * dx + dy * dy).squareRoot() // Negative because we want a smaller distance to be a higher priority
    }
}
