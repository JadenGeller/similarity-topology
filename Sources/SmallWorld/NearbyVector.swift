import PriorityHeapModule

public struct NearbyVector<ID: Hashable, Vector, Priority: Comparable, Metadata>: Identifiable, Prioritizable {
    public var id: ID
    public var vector: Vector
    public var priority: Priority
    public var metadata: Metadata
    
    public init(id: ID, vector: Vector, priority: Priority, metadata: Metadata) {
        self.id = id
        self.vector = vector
        self.priority = priority
        self.metadata = metadata
    }
}

extension NearbyVector where Metadata == Void {
    public init(id: ID, vector: Vector, priority: Priority) {
        self.init(id: id, vector: vector, priority: priority, metadata: ())
    }
    
    func withMetadata<NewMetadata>(_ metadata: NewMetadata) -> NearbyVector<ID, Vector, Priority, NewMetadata> {
        .init(id: id, vector: vector, priority: priority, metadata: metadata)
    }
}
