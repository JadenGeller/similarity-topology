import CoreLMDB
import CoreLMDBCoders

public struct DurableVectorRegistry {
    public typealias ForeignKey = String
    public typealias CompactKey = UInt32
    public typealias Vector = [Float32] // dimension 512

    typealias ForeignKeyCoder = StringByteCoder
    static var foreignKeyCoder: ForeignKeyCoder { .init() }

    typealias CompactKeyCoder = IntByteCoder<UInt32>
    static var compactKeyCoder: CompactKeyCoder { .init(UInt32.self, endianness: .big) }

    typealias VectorCoder = UnsafeMemoryLayoutVectorByteCoder<Vector.Element>
    static var vectorCoder: VectorCoder { .init(count: 512) }

    var compactKeyDatabase: RawDatabase
    var foreignKeyDatabase: RawDatabase
    var vectorComponentsDatabase: RawDatabase

    public init(namespace: String, in transaction: Transaction) throws {
        compactKeyDatabase = try .open("\(namespace)/compact-key", in: transaction)
        foreignKeyDatabase = try .open("\(namespace)/foreign-key", in: transaction)
        vectorComponentsDatabase = try .open("\(namespace)/components", in: transaction)
    }

    public struct Accessor {
        private var compactKeyCursor: Cursor<ForeignKeyCoder, CompactKeyCoder>
        private var foreignKeyCursor: Cursor<CompactKeyCoder, ForeignKeyCoder>
        private var vectorComponentsCursor: Cursor<CompactKeyCoder, VectorCoder>

        init(for store: DurableVectorRegistry, in transaction: Transaction) throws {
            compactKeyCursor = try Cursor(for: store.compactKeyDatabase, in: transaction)
                .rebind(to: .init(keyCoder: DurableVectorRegistry.foreignKeyCoder, valueCoder: DurableVectorRegistry.compactKeyCoder))
            foreignKeyCursor = try Cursor(for: store.foreignKeyDatabase, in: transaction)
                .rebind(to: .init(keyCoder: DurableVectorRegistry.compactKeyCoder, valueCoder: DurableVectorRegistry.foreignKeyCoder))
            vectorComponentsCursor = try Cursor(for: store.vectorComponentsDatabase, in: transaction)
                .rebind(to: .init(keyCoder: DurableVectorRegistry.compactKeyCoder, valueCoder: DurableVectorRegistry.vectorCoder))
        }

        private func nextKey() -> CompactKey {
            guard let lastKey = try! vectorComponentsCursor.get(.last)?.key else { return 0 }
            return lastKey + 1
        }

        public func register(_ vector: Vector, forForeignKey foreignKey: ForeignKey) -> CompactKey {
            let compactKey = nextKey()
            try! vectorComponentsCursor.put(vector, atKey: compactKey)
            try! foreignKeyCursor.put(foreignKey, atKey: compactKey)
            try! compactKeyCursor.put(compactKey, atKey: foreignKey)
            return compactKey
        }

        public func vector(forKey compactKey: CompactKey) -> Vector {
            guard let value = try! vectorComponentsCursor.get(atKey: compactKey)?.value else { preconditionFailure("Key not found") }
            return value
        }

        public func toForeignKey(forKey compactKey: CompactKey) -> ForeignKey {
            guard let value = try! foreignKeyCursor.get(atKey: compactKey)?.value else { preconditionFailure("Key not found") }
            return value
        }

        public func key(forForeignKey foreignKey: ForeignKey) -> CompactKey {
            guard let value = try! compactKeyCursor.get(atKey: foreignKey)?.value else { preconditionFailure("Key not found") }
            return value
        }
    }
}
