import Foundation
import os
import SwiftyDropbox

/// One-time migration of a v3 Dropbox login (vendored **ObjectiveDropboxOfficial** 7.4.x) into the **SwiftyDropbox** token store, so users updating to v4 stay signed in instead of being bounced to the login screen.
enum DropboxTokenMigration {

    private static let log = Logger(subsystem: "com.developerinsider.AppBox.core", category: "DropboxMigration")

    /// Convert any legacy archived tokens in the Keychain to SwiftyDropbox's JSON format.
    static func migrateIfNeeded() {
        guard let bundleId = Bundle.main.bundleIdentifier else { return }
        let service = "\(bundleId).dropbox.authv2"
        let storage = SecureStorageAccessDefaultImpl()

        var migrated = 0
        for uid in storage.getAllUserIds() {
            guard let data = rawKeychainData(service: service, account: uid) else { continue }
            if (try? JSONDecoder().decode(DropboxAccessToken.self, from: data)) != nil { continue }
            guard let legacy = LegacyDBAccessToken.decode(from: data) else { continue }
            let token = makeToken(from: legacy)
            guard let json = try? JSONEncoder().encode(token) else { continue }
            if storage.setAccessTokenData(for: uid, data: json) { migrated += 1 }
        }
        if migrated > 0 {
            log.info("Migrated \(migrated, privacy: .public) legacy Dropbox token(s) to SwiftyDropbox.")
        }
    }

    /// Map a decoded legacy token onto a SwiftyDropbox `DropboxAccessToken`.
    static func makeToken(from legacy: LegacyDBAccessToken) -> DropboxAccessToken {
        let refresh = (legacy.refreshToken?.isEmpty == false) ? legacy.refreshToken : nil
        let expiry = legacy.tokenExpirationTimestamp > 0 ? legacy.tokenExpirationTimestamp : nil
        return DropboxAccessToken(accessToken: legacy.accessToken, uid: legacy.uid,
                                  refreshToken: refresh, tokenExpirationTimestamp: expiry)
    }

    private static func rawKeychainData(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }
}

/// Minimal stand-in for the removed ObjectiveDropboxOfficial `DBAccessToken`, just enough to decode its `NSKeyedArchiver` representation.
final class LegacyDBAccessToken: NSObject, NSSecureCoding {
    static var supportsSecureCoding: Bool { true }

    let uid: String
    let accessToken: String
    let refreshToken: String?
    let tokenExpirationTimestamp: Double

    init(uid: String, accessToken: String, refreshToken: String?, tokenExpirationTimestamp: Double) {
        self.uid = uid
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.tokenExpirationTimestamp = tokenExpirationTimestamp
    }

    required init?(coder: NSCoder) {
        guard let uid = coder.decodeObject(of: NSString.self, forKey: "uid") as String?,
              let accessToken = coder.decodeObject(of: NSString.self, forKey: "accessToken") as String? else {
            return nil
        }
        self.uid = uid
        self.accessToken = accessToken
        self.refreshToken = coder.decodeObject(of: NSString.self, forKey: "refreshToken") as String?
        self.tokenExpirationTimestamp = coder.decodeDouble(forKey: "tokenExpirationTimestamp")
        super.init()
    }

    func encode(with coder: NSCoder) {
        coder.encode(uid as NSString, forKey: "uid")
        coder.encode(accessToken as NSString, forKey: "accessToken")
        coder.encode(refreshToken as NSString?, forKey: "refreshToken")
        coder.encode(tokenExpirationTimestamp, forKey: "tokenExpirationTimestamp")
    }

    /// Decode an `NSKeyedArchiver` archive whose root class is `DBAccessToken` into this stand-in.
    static func decode(from data: Data) -> LegacyDBAccessToken? {
        guard let unarchiver = try? NSKeyedUnarchiver(forReadingFrom: data) else { return nil }
        unarchiver.requiresSecureCoding = false
        unarchiver.setClass(LegacyDBAccessToken.self, forClassName: "DBAccessToken")
        let token = unarchiver.decodeObject(of: LegacyDBAccessToken.self, forKey: NSKeyedArchiveRootObjectKey)
        unarchiver.finishDecoding()
        return token
    }
}
