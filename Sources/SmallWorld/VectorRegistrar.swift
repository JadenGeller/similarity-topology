// TODO: Allow for durable iteration so can be reindexed
public protocol VectorRegistrar {
    associatedtype Key
    associatedtype Vector
    associatedtype Metadata
    
    // TODO: Should this throw if ID allocation fails?
    func register(_ vector: Vector, with metadata: Metadata) -> Key
    func vector(forKey key: Key) -> Vector
    func metadata(forKey key: Key) -> Metadata
}

public class InMemoryVectorRegistrar<Key: BinaryInteger, Vector, Metadata>: VectorRegistrar {
    private var nextKey: Key = 0
    public private(set) var vectors: [Vector] = []
    public private(set) var metadata: [Metadata] = []

    public init() { }
    
    public func register(_ vector: Vector, with metadata: Metadata) -> Key {
        self.vectors.append(vector)
        self.metadata.append(metadata)
        
        defer { nextKey += 1 }
        return nextKey
    }
    
    public func vector(forKey key: Key) -> Vector {
        vectors[Int(key)]
    }
    
    public func metadata(forKey key: Key) -> Metadata {
        metadata[Int(key)]
    }
}
