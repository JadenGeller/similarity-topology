public protocol GraphStorage {
    associatedtype Key: Hashable
    associatedtype Level: BinaryInteger
    
    var entry: Key? { get }
    var maxLevel: Level { get }
    func addLevel(with newEntry: Key)
    
    func neighborhood(around key: Key, on level: Level) -> [Key]
    func connect(_ key: Key, to other: Key, on level: Level)
    func disconnect(_ key: Key, from other: Key, on level: Level)
}

extension GraphStorage {
    public var descendingLevels: some Sequence<Level> {
        stride(from: maxLevel, through: 0, by: -1)
    }
}

public class InMemoryGraphStorage<Key: Hashable, Level: BinaryInteger>: GraphStorage {
    private struct NeighborhoodID: Hashable {
        var key: Key
        var level: Level
    }
    
    public init() { }
    
    public private(set) var entry: Key?
    public private(set) var maxLevel: Level = -1
    public func addLevel(with newEntry: Key) {
        entry = newEntry
        maxLevel += 1
    }
    
    private var connections: [Level: [Key: Set<Key>]] = [:]
    subscript(level: Level, key: Key) -> Set<Key> {
        get { connections[level, default: [:]][key, default: []] }
        set { connections[level, default: [:]][key, default: []] = newValue }
    }
    public func neighborhood(around key: Key, on level: Level) -> [Key] {
        Array(self[level, key])
    }
    public func connect(_ key: Key, to other: Key, on level: Level) {
        self[level, key].insert(other)
    }
    public func disconnect(_ key: Key, from other: Key, on level: Level) {
        self[level, key].remove(other)
    }
}

extension InMemoryGraphStorage {
    public func keys(on level: Level) -> some Sequence<Key> {
        var result = Set(connections[level, default: [:]].keys)
        if level == maxLevel, let entry {
            result.insert(entry)
        }
        return result
    }
}
