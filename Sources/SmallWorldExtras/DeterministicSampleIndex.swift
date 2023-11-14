import SmallWorld
import Foundation
import PriorityHeapModule
import PriorityHeapAlgorithms

public struct DeterministicSampleIndex {
    public typealias Index = InMemoryVectorIndex<Int, Int, CartesianDistanceMetric, Void>
    public var base: Index
    
    public init(typicalNeighborhoodSize: Int) {
        base = .init(metric: .init(), params: .unstableDefault(typicalNeighborhoodSize: typicalNeighborhoodSize))
    }
    
    private var vectorRNG = DeterministicRandomNumberGenerator(seed: 0)
    private var graphRNG = DeterministicRandomNumberGenerator(seed: 1)
    
    public func find(near query: CGPoint, limit: Int, exact: Bool = false) throws -> [Index.Neighbor] {
        if exact {
            Array(PriorityHeap(base.registrar.vectors.enumerated().map {
                let similarity = base.manager.metric.similarity(between: query, $0.element)
                return NearbyVector(id: $0.offset, vector: $0.element, priority: similarity)
            }).descending().prefix(limit))
        } else {
            Array(try base.find(near: query, limit: limit))
        }
    }
    
    public mutating func generateRandom(range: ClosedRange<Double>) -> CGPoint {
        CGPoint(
            x: .random(in: range, using: &vectorRNG),
            y: .random(in: range, using: &vectorRNG)
        )
    }
    
    public mutating func insertRandom(range: ClosedRange<Double>) {
        base.insert(generateRandom(range: range), with: (), using: &graphRNG)
    }
}

public struct CartesianDistanceMetric: SimilarityMetric {
    public func similarity(between someItem: CGPoint, _ otherItem: CGPoint) -> Double {
        let dx = someItem.x - otherItem.x
        let dy = someItem.y - otherItem.y
        return -(dx * dx + dy * dy).squareRoot()
    }
}
