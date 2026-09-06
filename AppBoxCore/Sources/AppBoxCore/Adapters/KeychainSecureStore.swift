import Foundation
import Security

/// Production `SecureStore` backed by the macOS Keychain (generic-password items).
public final class KeychainSecureStore: SecureStore {
    private let accessGroup: String?

    public init(accessGroup: String? = nil) {
        self.accessGroup = accessGroup
    }

    private func baseQuery(account: String?, service: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]
        if let account { query[kSecAttrAccount as String] = account }
        if let accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
            query[kSecUseDataProtectionKeychain as String] = true
        }
        return query
    }

    public func data(forAccount account: String, service: String) throws -> Data? {
        var query = baseQuery(account: account, service: service)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw SecureStoreError.keychain(status: status) }
        return item as? Data
    }

    public func set(_ data: Data, forAccount account: String, service: String) throws {
        let query = baseQuery(account: account, service: service)

        let updateStatus = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if updateStatus == errSecSuccess { return }
        guard updateStatus == errSecItemNotFound else { throw SecureStoreError.keychain(status: updateStatus) }

        var addQuery = query
        addQuery[kSecValueData as String] = data
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        guard addStatus == errSecSuccess else { throw SecureStoreError.keychain(status: addStatus) }
    }

    public func removeItem(forAccount account: String, service: String) throws {
        let status = SecItemDelete(baseQuery(account: account, service: service) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStoreError.keychain(status: status)
        }
    }

    public func accounts(forService service: String) throws -> [String] {
        var query = baseQuery(account: nil, service: service)
        query[kSecMatchLimit as String] = kSecMatchLimitAll
        query[kSecReturnAttributes as String] = true

        var items: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &items)
        if status == errSecItemNotFound { return [] }
        guard status == errSecSuccess else { throw SecureStoreError.keychain(status: status) }
        let attributeList = items as? [[String: Any]] ?? []
        return attributeList.compactMap { $0[kSecAttrAccount as String] as? String }
    }

    public func removeAllItems(forService service: String) throws {
        let status = SecItemDelete(baseQuery(account: nil, service: service) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStoreError.keychain(status: status)
        }
    }
}
