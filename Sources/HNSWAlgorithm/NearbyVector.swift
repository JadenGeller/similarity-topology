import PriorityHeapModule

public struct NearbyVector<ID: Hashable, Vector, Priority: Comparable>: Identifiable, Prioritizable {
    public var id: ID
    public var vector: Vector
    public var priority: Priority
    
    public init(id: ID, vector: Vector, priority: Priority) {
        self.id = id
        self.vector = vector
        self.priority = priority
    }
}

extension NearbyVector {
    @inlinable @inline(__always)
    public func mapID<MappedID: Hashable>(_ transform: (ID) throws -> MappedID) rethrows -> NearbyVector<MappedID, Vector, Priority> {
        .init(id: try transform(id), vector: vector, priority: priority)
    }
}
