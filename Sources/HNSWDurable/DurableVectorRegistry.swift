import CoreLMDB
import CoreLMDBCoders

public struct DurableVectorRegistry<VectorComponent: UnsafeMemoryLayoutStorableFloat> {
    public typealias ForeignKey = String
    public typealias CompactKey = UInt32
    public typealias Vector = [VectorComponent] // dimension 512

    public typealias ForeignKeyCoder = StringByteCoder
    public static var foreignKeyCoder: ForeignKeyCoder { .init() }

    public typealias CompactKeyCoder = IntByteCoder<UInt32>
    public static var compactKeyCoder: CompactKeyCoder { .init(UInt32.self, endianness: .big) }

    public typealias VectorCoder = UnsafeMemoryLayoutVectorByteCoder<Vector.Element>
    public static var vectorCoder: VectorCoder { .init(count: 512) }

    @usableFromInline
    internal var compactKeyDatabase: RawDatabase
    
    @usableFromInline
    internal var foreignKeyDatabase: RawDatabase
    
    @usableFromInline
    internal var vectorComponentsDatabase: RawDatabase

    
    @inlinable
    public init(namespace: String, in transaction: Transaction) throws {
        compactKeyDatabase = try .open("\(namespace)/compact-key", in: transaction)
        foreignKeyDatabase = try .open("\(namespace)/foreign-key", in: transaction)
        vectorComponentsDatabase = try .open("\(namespace)/components", in: transaction)
    }
    
    @inlinable @inline(__always)
    public static var countNamedDBs: Int { 3 }

    public func dropDatabase(in transaction: Transaction) throws {
        try compactKeyDatabase.drop(close: false, in: transaction)
        try foreignKeyDatabase.drop(close: false, in: transaction)
        try vectorComponentsDatabase.drop(close: false, in: transaction)
    }
    
    public struct Accessor {
        @usableFromInline
        internal var compactKeyCursor: Cursor<ForeignKeyCoder, CompactKeyCoder>
        
        @usableFromInline
        internal var foreignKeyCursor: Cursor<CompactKeyCoder, ForeignKeyCoder>
        
        @usableFromInline
        internal var vectorComponentsCursor: Cursor<CompactKeyCoder, VectorCoder>

        @inlinable
        public init(for store: DurableVectorRegistry, in transaction: Transaction) throws {
            compactKeyCursor = try Cursor(for: store.compactKeyDatabase, in: transaction)
                .rebind(to: .init(keyCoder: DurableVectorRegistry.foreignKeyCoder, valueCoder: DurableVectorRegistry.compactKeyCoder))
            foreignKeyCursor = try Cursor(for: store.foreignKeyDatabase, in: transaction)
                .rebind(to: .init(keyCoder: DurableVectorRegistry.compactKeyCoder, valueCoder: DurableVectorRegistry.foreignKeyCoder))
            vectorComponentsCursor = try Cursor(for: store.vectorComponentsDatabase, in: transaction)
                .rebind(to: .init(keyCoder: DurableVectorRegistry.compactKeyCoder, valueCoder: DurableVectorRegistry.vectorCoder))
        }

        @inlinable
        internal func nextKey() -> CompactKey {
            guard let lastKey = try! vectorComponentsCursor.get(.last)?.key else { return 0 }
            return lastKey + 1
        }

        @inlinable
        public func register(_ vector: Vector, forForeignKey foreignKey: ForeignKey) -> CompactKey {
            let compactKey = nextKey()
            try! vectorComponentsCursor.put(vector, atKey: compactKey, precondition: .uniqueKey)
            try! foreignKeyCursor.put(foreignKey, atKey: compactKey, precondition: .uniqueKey)
            try! compactKeyCursor.put(compactKey, atKey: foreignKey, precondition: .uniqueKey)
            return compactKey
        }

        @inlinable
        public func vector(forKey compactKey: CompactKey) -> Vector {
            guard let value = try! vectorComponentsCursor.get(atKey: compactKey)?.value else { preconditionFailure("Key not found") }
            return value
        }
        
        @inlinable
        public func toForeignKey(forKey compactKey: CompactKey) -> ForeignKey {
            guard let value = try! foreignKeyCursor.get(atKey: compactKey)?.value else { preconditionFailure("Key not found") }
            return value
        }

        @inlinable
        public func key(forForeignKey foreignKey: ForeignKey) -> CompactKey? {
            guard let value = try! compactKeyCursor.get(atKey: foreignKey)?.value else { return nil }
            return value
        }
        
        @inlinable
        public func hasVector(forForeignKey foreignKey: ForeignKey) -> Bool {
            try! compactKeyCursor.get(atKey: foreignKey) != nil
        }
        
        @inlinable
        public func vector(forForeignKey foreignKey: ForeignKey) -> Vector? {
            guard let compactKey = key(forForeignKey: foreignKey) else { return nil }
            return vector(forKey: compactKey)
        }
    }
}
