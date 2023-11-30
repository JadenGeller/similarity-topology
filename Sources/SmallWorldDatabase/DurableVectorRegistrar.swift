import SmallWorld
import CoreLMDB
import CoreLMDBCoders

public protocol VectorProtocol {
    associatedtype Element: UnsafeMemoryLayoutStorable
    static var dimension: Int { get }
    init(_ components: Array<Element>)
    var components: Array<Element> { get }
}

// TODO: Allow for durable iteration so can be reindexed
public struct DurableVectorRegistrar<Vector: VectorProtocol, MetadataCoder: ByteCoder>: VectorRegistrar where MetadataCoder.Input == MetadataCoder.Output {
    public typealias Key = UInt32
    public typealias Metadata = MetadataCoder.Input

    typealias KeyCoder = IntByteCoder<Key>
    static var keyCoder: KeyCoder { .init(Key.self, endianness: .little) }

    typealias VectorCoder = UnsafeMemoryLayoutVectorByteCoder<Vector.Element>
    static var vectorCoder: VectorCoder { .init(count: Vector.dimension) }

    typealias RegistrationCoder = TupleByteCoder<VectorCoder, MetadataCoder>

    private var cursor: Cursor<KeyCoder, RegistrationCoder>
    init(cursor: RawCursor, metadataCoder: MetadataCoder) {
        self.cursor = cursor.bind(to: .init(
            keyCoder: Self.keyCoder,
            valueCoder: TupleByteCoder(
                Self.vectorCoder,
                metadataCoder
            )
        ))
    }
    
    public func register(_ vector: Vector, with metadata: Metadata) -> Key {
        let nextKey = (try! cursor.get(.last)?.key).map({ $0 + 1 }) ?? 0
        try! cursor.put((vector.components, metadata), atKey: nextKey, overwrite: true)
        return nextKey
    }
    
    public func vector(forKey key: Key) -> Vector {
        guard let value = try! cursor.get(atKey: key)?.value else { preconditionFailure("Key not found") }
        return .init(value.0)
    }
    
    public func metadata(forKey key: Key) -> Metadata {
        guard let value = try! cursor.get(atKey: key)?.value else { preconditionFailure("Key not found") }
        return value.1
    }
}
