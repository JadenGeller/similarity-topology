import SmallWorld
import CoreLMDB
import CoreLMDBCoders

public struct DurableGraphStorage: GraphStorage {
    public typealias Level = UInt8
    public typealias Key = UInt32
        
    typealias LevelCoder = IntByteCoder<Level>
    static var levelCoder: LevelCoder { .init(Level.self, endianness: .big) }
    
    typealias KeyCoder = IntByteCoder<Key>
    static var keyCoder: KeyCoder { .init(Key.self, endianness: .little) }

    typealias LevelKeyCoder = TupleByteCoder<LevelCoder, KeyCoder>
    static var levelKeyCoder: LevelKeyCoder { .init(levelCoder, keyCoder) }
    
    static var neighborhoodSchema: DatabaseSchema<LevelKeyCoder, UnsafeMemoryLayoutArrayByteCoder<Key>> {
        .init(
            keyCoder: levelKeyCoder,
            valueCoder: UnsafeMemoryLayoutArrayByteCoder<Key>()
        )
    }
    
    // importantly, entry schema key is different size than neighborhood schema key, so they're distinguishable
    static var entrySchema: DatabaseSchema<LevelCoder, LevelKeyCoder> {
        .init(
            keyCoder: levelCoder, // in practice, we only use the max value!
            valueCoder: levelKeyCoder
        )
    }
    private static let entryKey: Level = .max

    private var cursor: RawCursor
    init(cursor: RawCursor) {
        self.cursor = cursor
    }
    
    public var entry: (key: Key, level: Level)? {
        guard let (level, key) = try! cursor.bind(to: Self.entrySchema).get(atKey: Self.entryKey)?.value else { return nil }
        return (key, level)
    }

    public func register(_ key: Key, on insertionLevel: Level) {
        try! cursor.bind(to: Self.entrySchema).put((insertionLevel, key), atKey: Self.entryKey)
    }
    
    public func neighborhood(around key: Key, on level: Level) -> [Key] {
        guard let item = try! cursor.bind(to: Self.neighborhoodSchema).get(atKey: (level, key))?.value else { return [] }
        return Array(item)
    }
    
    public func replaceNeighborhood(around key: UInt32, on level: UInt8, with newNeighbors: [UInt32]) {
        try! cursor.bind(to: Self.neighborhoodSchema).put(newNeighbors, atKey: (level, key), overwrite: true)
    }
}
