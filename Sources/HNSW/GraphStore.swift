public protocol GraphStore {
    associatedtype Key: Hashable
    associatedtype Level: BinaryInteger
    
    var entry: (key: Key, level: Level)? { get nonmutating set }
    
    func connect(_ lhs: Key, to rhs: Key, on level: Level)
    func disconnect(_ lhs: Key, from rhs: Key, on level: Level)
    func neighborhood(around key: Key, on level: Level) -> [Key]
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
    
    public var entry: (key: Key, level: Level)?
    private var connections: [Level: [Key: Set<Key>]] = [:]
    subscript(level: Level, key: Key) -> Set<Key> {
        get { connections[level, default: [:]][key, default: []] }
        set { connections[level, default: [:]][key, default: []] = newValue }
    }
    public func neighborhood(around key: Key, on level: Level) -> [Key] {
        Array(self[level, key])
    }
    
    public func connect(_ lhs: Key, to rhs: Key, on level: Level) {
        self[level, lhs].insert(rhs)
    }
    public func disconnect(_ lhs: Key, from rhs: Key, on level: Level) {
        self[level, lhs].remove(rhs)
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
