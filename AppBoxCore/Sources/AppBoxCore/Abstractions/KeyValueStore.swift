import Foundation

/// Abstraction over a small key/value preferences store (production: `UserDefaults`).
public protocol KeyValueStore: AnyObject {
    func bool(forKey key: String) -> Bool
    func integer(forKey key: String) -> Int
    func string(forKey key: String) -> String?
    func data(forKey key: String) -> Data?
    func object(forKey key: String) -> Any?

    func set(_ value: Any?, forKey key: String)
    func removeObject(forKey key: String)
}
