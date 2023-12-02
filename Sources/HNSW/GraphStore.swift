public protocol GraphStore {
    associatedtype Key: Hashable
    associatedtype Level: BinaryInteger
    
    var entry: (level: Level, key: Key)? { get nonmutating set }
    
    func connect(on level: Level, _ keys: (Key, Key)) // bidirectional!
    func disconnect(on level: Level, _ keys: (Key, Key)) // bidirectional!
    func neighborhood(on level: Level, around key: Key) -> [Key]
}

extension GraphStore {
    @discardableResult @inlinable @inline(__always)
    public func descend(_ level: inout Level?) -> Level? {
        defer {
            switch level {
            case nil: break
            case 0: level = nil
            case let currentLevel?: level = currentLevel - 1
            }
        }
        return level
    }
}

public class InMemoryGraphStorage<Key: Hashable, Level: BinaryInteger>: GraphStore {
    private struct NeighborhoodID: Hashable {
        var key: Key
        var level: Level
    }
    
    public init() { }
    
    public var entry: (level: Level, key: Key)?
    private var connections: [Level: [Key: Set<Key>]] = [:]
    subscript(level: Level, key: Key) -> Set<Key> {
        get { connections[level, default: [:]][key, default: []] }
        set { connections[level, default: [:]][key, default: []] = newValue }
    }
    public func neighborhood(on level: Level, around key: Key) -> [Key] {
        Array(self[level, key])
    }
    
    public func connect(on level: Level, _ keys: (Key, Key)) {
        self[level, keys.0].insert(keys.1)
        self[level, keys.1].insert(keys.0)
    }
    public func disconnect(on level: Level, _ keys: (Key, Key)) {
        self[level, keys.0].remove(keys.1)
        self[level, keys.1].remove(keys.0)
    }
}

extension InMemoryGraphStorage {
    public func keys(on level: Level) -> some Sequence<Key> {
        var result = Set(connections[level, default: [:]].keys)
        if let entry, entry.level == level {
            result.insert(entry.key)
        }
        return result
    }
}
