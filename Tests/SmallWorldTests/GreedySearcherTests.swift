import XCTest
import SmallWorld

final class GreedySearcherTests: XCTestCase {
    func search<Element: Comparable>(_ tree: AdjacencyTree<Element>, limit: Int) -> [Element] {
        var searcher = GreedySearcher(from: [.rootID], prioritize: tree.priorityVertex)
        searcher.refine(using: tree, limit: limit)
        return Array(searcher.optimal.descending().lazy.map(\.priority))
    }
    
    func testFindsMaxInMonotonicLine() {
        XCTAssertEqual(10, search(.init(line: Array(1...10))!, limit: 1).first)
        XCTAssertEqual(10, search(.init(line: Array(1...10).reversed())!, limit: 1).first)
    }
    
    func testFindsMaxRespectingCapacity() {
        XCTAssertEqual(3, search(.init(line: [1, 2, 3, 2, 4, 5])!, limit: 1).first)
        XCTAssertEqual(3, search(.init(line: [1, 2, 3, 2, 4, 5])!, limit: 2).first)
        XCTAssertEqual(3, search(.init(line: [1, 2, 3, 2, 4, 5])!, limit: 3).first)
        XCTAssertEqual(3, search(.init(line: [1, 3, 2, 4, 5])!, limit: 2).first)
        XCTAssertEqual(1, search(.init(line: [0, 1, 1, 1, 1, 5])!, limit: 4).first)
        XCTAssertEqual(5, search(.init(line: [0, 1, 1, 1, 1, 5])!, limit: 5).first)
    }

    func testFailsToFindIfThereIsBetterDirection() {
        let tree = AdjacencyTree(0, [
            AdjacencyTree(-1, [
                AdjacencyTree(9),
            ]),
            AdjacencyTree(1, [
                AdjacencyTree(2),
                AdjacencyTree(3),
            ])
        ])
        XCTAssertEqual(search(tree, limit: 2), [3, 2])
    }
}



//    func testGreedySearcher() {
////        // Create a simple graph
////        let graph = SimpleGraph<GraphVertex>()
////        var rng = DeterministicRandomNumberGenerator(seed: 1)
////
////        // Add some vertices and edges
////        let vertices = (1...100).map { GraphVertex(id: $0, value: Int.random(in: 1...100, using: &rng)) }
////        vertices.forEach { vertex in
////            graph.addEdge(from: vertex, to: vertices[Int.random(in: 0..<vertices.count, using: &rng)])
////            graph.addEdge(from: vertex, to: vertices[Int.random(in: 0..<vertices.count, using: &rng)])
////            graph.addEdge(from: vertex, to: vertices[Int.random(in: 0..<vertices.count, using: &rng)])
////            graph.addEdge(from: vertex, to: vertices[Int.random(in: 0..<vertices.count, using: &rng)])
////            graph.addEdge(from: vertex, to: vertices[Int.random(in: 0..<vertices.count, using: &rng)])
////            graph.addEdge(from: vertex, to: vertices[Int.random(in: 0..<vertices.count, using: &rng)])
////            graph.addEdge(from: vertex, to: vertices[Int.random(in: 0..<vertices.count, using: &rng)])
////            graph.addEdge(from: vertex, to: vertices[Int.random(in: 0..<vertices.count, using: &rng)])
////            graph.addEdge(from: vertex, to: vertices[Int.random(in: 0..<vertices.count, using: &rng)])
////            graph.addEdge(from: vertex, to: vertices[Int.random(in: 0..<vertices.count, using: &rng)])
////        }
////        
////        // Define a priority function
////        let prioritize: (GraphVertex) -> GraphVertex = { $0 }
////        
////        // Initialize the GreedySearcher
////        var searcher = GreedySearcher(from: Array(vertices.prefix(2)), prioritize: prioritize)
////                
////        // Perform the search with a capacity limit
////        searcher.refine(using: graph, limit: 5)
////        
////        // Check the results
////        let optimalVertices = searcher.optimal.unordered.map { $0.item }
////        print("Optimal vertices: \(optimalVertices)")
////        print("VS", vertices.sorted(by: { $0.priority > $1.priority }).prefix(5))
////        
//        // Add assertions as needed to validate the results
//        // For example, check if the optimal set contains the vertices with the highest priorities
//        // This will depend on the specific priority metric and graph structure
//    }
//}
