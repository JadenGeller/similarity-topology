public protocol GraphManager {
    associatedtype Key: Hashable
    associatedtype Level: BinaryInteger
    
    var entry: (level: Level, key: Key)? { get nonmutating set }
    
    func connect(on level: Level, _ keys: (Key, Key)) // bidirectional!
    func disconnect(on level: Level, _ keys: (Key, Key)) // bidirectional!
    func neighborhood(on level: Level, around key: Key) -> [Key]
}

extension GraphManager {
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
