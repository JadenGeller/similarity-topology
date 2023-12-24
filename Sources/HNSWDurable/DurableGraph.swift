import HNSWAlgorithm
import CoreLMDB
import CoreLMDBCells
import CoreLMDBCoders

public struct DurableGraph {
    public typealias Level = UInt8
    public typealias Key = UInt32
        
    public typealias LevelCoder = IntByteCoder<Level>
    public static var levelCoder: LevelCoder { .init(Level.self, endianness: .big) }
    
    public typealias KeyCoder = IntByteCoder<Key>
    public static var keyCoder: KeyCoder { .init(Key.self, endianness: .big) }

    public typealias LevelKeyCoder = TupleByteCoder<LevelCoder, KeyCoder>
    public static var levelKeyCoder: LevelKeyCoder { .init(levelCoder, keyCoder) }
    
    @usableFromInline
    internal var adjacencyDatabase: RawDatabase
    
    @usableFromInline
    internal var mainDatabase: RawDatabase
    
    @usableFromInline
    internal var entryKey: ContiguousArray<UInt8>
    
    @inlinable
    public init(namespace: String, in transaction: Transaction) throws {
        adjacencyDatabase = try .open("\(namespace)/adjacency", config: .init(duplicateHandling: .init()), in: transaction)
        mainDatabase = try .open(in: transaction)
        entryKey = try StringByteCoder().withEncoding(of: "\(namespace)/entry", ContiguousArray<UInt8>.init)
    }
    
    @inlinable @inline(__always)
    public static var countNamedDBs: Int { 1 }
    
    public func dropDatabase(in transaction: Transaction) throws {
        try adjacencyDatabase.drop(close: false, in: transaction)
        try mainDatabase.delete(atKey: entryKey, in: transaction)
    }
    
    public struct Accessor: GraphManager {
        @usableFromInline
        internal var adjacencyCursor: Cursor<LevelKeyCoder, KeyCoder>
        
        @usableFromInline
        internal var entryCell: SingleValueCell<LevelKeyCoder>
        
        @inlinable
        public init(for store: DurableGraph, in transaction: Transaction) throws {
            adjacencyCursor = try Cursor(for: store.adjacencyDatabase, in: transaction)
                .rebind(to: .init(keyCoder: DurableGraph.levelKeyCoder, valueCoder: DurableGraph.keyCoder))
            entryCell = try SingleValueCell(atKey: store.entryKey, for: store.mainDatabase, in: transaction)
                .rebind(to: DurableGraph.levelKeyCoder)
        }
        
        @inlinable
        public var entry: (level: Level, key: Key)? {
            get {
                try! entryCell.get()
            }
            nonmutating set {
                guard let newValue else { return try! entryCell.delete() }
                try! entryCell.put(newValue)
            }
        }
        
        @inlinable
        public func connect(on level: UInt8, _ keys: (UInt32, UInt32)) {
            try! adjacencyCursor.put(keys.1, atKey: (level, keys.0))
            try! adjacencyCursor.put(keys.0, atKey: (level, keys.1))
        }
        
        @inlinable
        public func disconnect(on level: UInt8, _ keys: (UInt32, UInt32)) {
            if try! adjacencyCursor.get(atKey: (level, keys.0), value: keys.1) != nil {
                try! adjacencyCursor.delete(target: .value)
            } else {
                print("error: connection does not exist from key \(keys.0) to key \(keys.1) on level \(level)")
            }
            if try! adjacencyCursor.get(atKey: (level, keys.1), value: keys.0) != nil {
                try! adjacencyCursor.delete(target: .value)
            } else {
                print("error: connection does not exist from key \(keys.1) to key \(keys.0) on level \(level)")
            }
        }
        
        @inlinable
        public func neighborhood(on level: Level, around key: Key) -> [Key] {
            var result: [Key] = []
            guard let first = try! adjacencyCursor.get(atKey: (level, key)) else { return result }
            result.append(first.value)
            while let next = try! adjacencyCursor.get(.next, target: .value) {
                result.append(next.value)
            }
            return result
        }
    }
}
