import Foundation

/// Error surface for `SecureStore` operations.
public enum SecureStoreError: Error, Equatable {
    /// An `OSStatus` returned by the Keychain Services API.
    case keychain(status: Int32)
    /// The stored payload existed but could not be decoded as expected.
    case malformedData
}

/// Abstraction over secure credential storage (production: the macOS Keychain).
public protocol SecureStore: AnyObject {
    func data(forAccount account: String, service: String) throws -> Data?
    func set(_ data: Data, forAccount account: String, service: String) throws
    func removeItem(forAccount account: String, service: String) throws

    /// All account identifiers currently stored for `service`.
    func accounts(forService service: String) throws -> [String]
    func removeAllItems(forService service: String) throws
}

public extension SecureStore {
    /// Convenience: store a UTF-8 string.
    func setString(_ value: String, forAccount account: String, service: String) throws {
        try set(Data(value.utf8), forAccount: account, service: service)
    }

    /// Convenience: read a UTF-8 string.
    func string(forAccount account: String, service: String) throws -> String? {
        guard let data = try data(forAccount: account, service: service) else { return nil }
        guard let string = String(data: data, encoding: .utf8) else { throw SecureStoreError.malformedData }
        return string
    }
}
