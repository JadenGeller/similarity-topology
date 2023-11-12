import XCTest
@testable import SmallWorld

final class HierarchicalNavigableSmallWorldTests: XCTestCase {
    func testInsertAndNeighborhood() {
        var graph = RandomGraph()
        graph.insertRandomData(count: 100)
        
        for i in 0..<10 {
            let sample = graph.randomData()
            print("iter \(i): \(sample)")
            let hnswResults = Array(try! graph.hnsw.neighborhood(around: sample, size: 10))
            let exactResult = graph.findExact(around: sample)
            print("found: \(hnswResults.map(\.data))")
            print("exact: \(exactResult.map(\.value))")
            XCTAssert(exactResult.contains(where: { $0.key == hnswResults[0].item }))
        }
    }
}

