import Foundation
import SwiftyDropbox

/// A `SecureStorageAccess` for non-app contexts (the CLI).
public final class CLISecureStorageAccess: SecureStorageAccess {

    private let service: String

    public init(service: String) {
        self.service = service
    }

    public func checkAccessibilityMigrationOneTime() {
    }

    public func setAccessTokenData(for userId: String, data: Data) -> Bool {
        let query = query(account: userId, extra: [kSecValueData as String: data as AnyObject])
        SecItemDelete(query)
        return SecItemAdd(query, nil) == errSecSuccess
    }

    public func getAllUserIds() -> [String] {
        let query = query(account: nil, extra: [
            kSecReturnAttributes as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitAll,
        ])
        var result: AnyObject?
        guard SecItemCopyMatching(query, &result) == errSecSuccess else { return [] }
        let items = result as? [[String: AnyObject]] ?? []
        return items.compactMap { $0[kSecAttrAccount as String] as? String }
    }

    public func getDropboxAccessToken(for key: String) -> DropboxAccessToken? {
        guard let data = data(for: key) else { return nil }
        if let token = try? JSONDecoder().decode(DropboxAccessToken.self, from: data) {
            return token
        }
        if let string = String(data: data, encoding: .utf8) {
            return DropboxAccessToken(accessToken: string, uid: key)
        }
        return nil
    }

    public func deleteInfo(for key: String) -> Bool {
        SecItemDelete(query(account: key, extra: [:])) == errSecSuccess
    }

    public func deleteInfoForAllKeys() -> Bool {
        SecItemDelete(query(account: nil, extra: [:])) == errSecSuccess
    }

    // MARK: Helpers

    private func data(for key: String) -> Data? {
        let query = query(account: key, extra: [
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ])
        var result: AnyObject?
        guard SecItemCopyMatching(query, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    private func query(account: String?, extra: [String: AnyObject]) -> CFDictionary {
        var dict: [String: AnyObject] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service as AnyObject,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        if let account { dict[kSecAttrAccount as String] = account as AnyObject }
        for (key, value) in extra { dict[key] = value }
        return dict as CFDictionary
    }
}
