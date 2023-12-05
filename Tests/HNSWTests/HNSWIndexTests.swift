import XCTest
import HNSW
import HNSWSample

final class HNSWIndexTests: XCTestCase {
    func testInsertAndNeighborhood() {
        var index = DeterministicSampleVectorIndex(typicalNeighborhoodSize: 20)
        for _ in 0..<100 {
            index.insertRandom(range: 0...1)
        }
        
        for i in 0..<10 {
            let sample = index.generateRandom(range: 0...1)
            print("iter \(i): \(sample)")
            let hnswResults = try! index.find(near: sample, limit: 10)
            let exactResult = try! index.find(near: sample, limit: 1, exact: true)
            XCTAssert(exactResult.contains(where: { $0.id == hnswResults[0].id }))
        }
    }
}

