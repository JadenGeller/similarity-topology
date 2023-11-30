public protocol GraphStorage {
    associatedtype Key: Hashable
    associatedtype Level: BinaryInteger
    
    var entry: (key: Key, level: Level)? { get }
    func register(_ key: Key, on insertionLevel: Level)
    
    func neighborhood(around key: Key, on level: Level) -> [Key]
    func replaceNeighborhood(around key: Key, on level: Level, with newNeighbors: [Key])
}

extension GraphStorage {
    @inlinable @inline(__always)
    public func descendingLevels(from first: Level? = nil, through last: Level = 0) -> some Sequence<Level> {
        guard let entry else { return stride(from: 1, through: 0, by: -1) /* empty */ }
        guard let first else { return stride(from: entry.level, through: last, by: -1) }
        assert(first <= entry.level)
        return stride(from: first, through: last, by: -1)
    }
}

public class InMemoryGraphStorage<Key: Hashable, Level: BinaryInteger>: GraphStorage {
    private struct NeighborhoodID: Hashable {
        var key: Key
        var level: Level
    }
    
    public init() { }
    
    public private(set) var entry: (key: Key, level: Level)?
    public func register(_ key: Key, on insertionLevel: Level) {
        guard let entry else { return entry = (key, insertionLevel) }
        guard insertionLevel > entry.level else { return }
        self.entry = (key, insertionLevel)
    }
    
    private var connections: [Level: [Key: Set<Key>]] = [:]
    subscript(level: Level, key: Key) -> Set<Key> {
        get { connections[level, default: [:]][key, default: []] }
        set { connections[level, default: [:]][key, default: []] = newValue }
    }
    public func neighborhood(around key: Key, on level: Level) -> [Key] {
        Array(self[level, key])
    }
    public func replaceNeighborhood(around key: Key, on level: Level, with newNeighbors: [Key]) {
        self[level, key] = Set(newNeighbors)
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
