import XCTest
import HNSW

final class GreedySearcherTests: XCTestCase {
    func search<Element: Comparable>(capacity: Int, _ tree: AdjacencyTree<Element>) -> [Element] {
        var searcher = GreedySearcher(initial: [.root], prioritize: tree.priorityIndex)
        searcher.refine(capacity: capacity, neighborhood: tree.neighborhood)
        return Array(searcher.optimal.descending().lazy.map(\.priority))
    }
    
    func testFindsMaxInMonotonicLine() {
        XCTAssertEqual(10, search(capacity: 1, .init(line: Array(1...10))!).first)
        XCTAssertEqual(10, search(capacity: 1, .init(line: Array(1...10).reversed())!).first)
    }
    
    func testFindsMaxRespectingCapacity() {
        XCTAssertEqual(3, search(capacity: 1, .init(line: [1, 2, 3, 2, 4, 5])!).first)
        XCTAssertEqual(3, search(capacity: 2, .init(line: [1, 2, 3, 2, 4, 5])!).first)
        XCTAssertEqual(3, search(capacity: 3, .init(line: [1, 2, 3, 2, 4, 5])!).first)
        XCTAssertEqual(3, search(capacity: 2, .init(line: [1, 3, 2, 4, 5])!).first)
        XCTAssertEqual(1, search(capacity: 4, .init(line: [0, 1, 1, 1, 1, 5])!).first)
        XCTAssertEqual(5, search(capacity: 5, .init(line: [0, 1, 1, 1, 1, 5])!).first)
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
        XCTAssertEqual(search(capacity: 2, tree), [3, 2])
    }
}
