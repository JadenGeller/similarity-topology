import HNSWAlgorithm

public class EphemeralGraph<Key: Hashable, Level: BinaryInteger>: GraphManager {
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

extension EphemeralGraph {
    public func keys(on level: Level) -> some Sequence<Key> {
        var result = Set(connections[level, default: [:]].keys)
        if let entry, entry.level == level {
            result.insert(entry.key)
        }
        return result
    }
}
