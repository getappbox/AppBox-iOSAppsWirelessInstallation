import Foundation

/// Production `KeyValueStore` backed by `UserDefaults`.
public final class UserDefaultsKeyValueStore: KeyValueStore {
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func bool(forKey key: String) -> Bool { defaults.bool(forKey: key) }
    public func integer(forKey key: String) -> Int { defaults.integer(forKey: key) }
    public func string(forKey key: String) -> String? { defaults.string(forKey: key) }
    public func data(forKey key: String) -> Data? { defaults.data(forKey: key) }
    public func object(forKey key: String) -> Any? { defaults.object(forKey: key) }
    public func set(_ value: Any?, forKey key: String) { defaults.set(value, forKey: key) }
    public func removeObject(forKey key: String) { defaults.removeObject(forKey: key) }
}
