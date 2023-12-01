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
    
    static var neighborhoodSchema: DatabaseSchema<LevelKeyCoder, KeyCoder> {
        .init(
            keyCoder: levelKeyCoder,
            valueCoder: keyCoder
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

    private var cursor: RawCursor // DUPSORT!
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
    
    public func connect(_ lhs: UInt32, to rhs: UInt32, on level: UInt8) {
        try! cursor.bind(to: Self.neighborhoodSchema).put(rhs, atKey: (level, lhs))
    }
    
    public func disconnect(_ lhs: UInt32, from rhs: UInt32, on level: UInt8) {
        try! cursor.bind(to: Self.neighborhoodSchema).get(atKey: (level, lhs), value: rhs)
        try! cursor.bind(to: Self.neighborhoodSchema).delete(target: .value)
    }
    
    public func neighborhood(around key: Key, on level: Level) -> [Key] {
        var result: [Key] = []
        guard let first = try! cursor.bind(to: Self.neighborhoodSchema).get(atKey: (level, key)) else { return result }
        result.append(first.value)
        while let next = try! cursor.bind(to: Self.neighborhoodSchema).get(.next, target: .value) {
            result.append(next.value)
        }
        return result
    }
}
