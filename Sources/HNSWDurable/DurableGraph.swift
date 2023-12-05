import HNSW
import CoreLMDB
import CoreLMDBCells
import CoreLMDBCoders

public struct DurableGraph {
    public typealias Level = UInt8
    public typealias Key = UInt32
        
    typealias LevelCoder = IntByteCoder<Level>
    static var levelCoder: LevelCoder { .init(Level.self, endianness: .big) }
    
    typealias KeyCoder = IntByteCoder<Key>
    static var keyCoder: KeyCoder { .init(Key.self, endianness: .big) }

    typealias LevelKeyCoder = TupleByteCoder<LevelCoder, KeyCoder>
    static var levelKeyCoder: LevelKeyCoder { .init(levelCoder, keyCoder) }
    
    var adjacencyDatabase: RawDatabase
    var mainDatabase: RawDatabase
    var entryKey: ContiguousArray<UInt8>

    init(namespace: String, in transaction: Transaction) throws {
        adjacencyDatabase = try .open("\(namespace)/adjacency", config: .init(duplicateHandling: .init()), in: transaction)
        mainDatabase = try .open(in: transaction)
        entryKey = try StringByteCoder().withEncoding(of: "\(namespace)/entry", ContiguousArray<UInt8>.init)
    }
    
    public struct Accessor: GraphManager {
        private var adjacencyCursor: Cursor<LevelKeyCoder, KeyCoder>
        private var entryCell: SingleValueCell<LevelKeyCoder>
        
        init(for store: DurableGraph, in transaction: Transaction) throws {
            adjacencyCursor = try Cursor(for: store.adjacencyDatabase, in: transaction)
                .rebind(to: .init(keyCoder: DurableGraph.levelKeyCoder, valueCoder: DurableGraph.keyCoder))
            entryCell = try SingleValueCell(atKey: store.entryKey, for: store.mainDatabase, in: transaction)
                .rebind(to: DurableGraph.levelKeyCoder)
        }
        
        public var entry: (level: Level, key: Key)? {
            get {
                try! entryCell.get()
            }
            nonmutating set {
                guard let newValue else { return try! entryCell.delete() }
                try! entryCell.put(newValue)
            }
        }
        
        public func connect(on level: UInt8, _ keys: (UInt32, UInt32)) {
            try! adjacencyCursor.put(keys.1, atKey: (level, keys.0))
            try! adjacencyCursor.put(keys.0, atKey: (level, keys.1))
        }
        
        public func disconnect(on level: UInt8, _ keys: (UInt32, UInt32)) {
            try! adjacencyCursor.get(atKey: (level, keys.0))
            try! adjacencyCursor.delete(target: .value)
            try! adjacencyCursor.get(atKey: (level, keys.1))
            try! adjacencyCursor.delete(target: .value)
        }
        
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
