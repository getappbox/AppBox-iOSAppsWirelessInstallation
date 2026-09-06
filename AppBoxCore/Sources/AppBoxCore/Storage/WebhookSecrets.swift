import Foundation
import os

/// Stores the webhook-notification secrets (Slack / Microsoft Teams incoming-webhook URLs) in the Keychain instead of plaintext `UserDefaults` — security item **S3** — and migrates any value an earlier version left in `UserDefaults` into the Keychain once, then removes the `UserDefaults` key.
public final class WebhookSecrets: NSObject {

    public static let shared = WebhookSecrets()

    private static let service = "com.developerinsider.AppBox.webhooks"
    private static let log = Logger(subsystem: "com.developerinsider.AppBox.core", category: "WebhookSecrets")

    /// The three secrets: their Keychain account and the legacy `UserDefaults` key they migrate from.
    private enum Secret: CaseIterable {
        case slack, teams
        var account: String {
            switch self {
            case .slack: return "slack"
            case .teams: return "msteams"
            }
        }
        var legacyDefaultsKey: String {
            switch self {
            case .slack: return "UserSlackChannel"
            case .teams: return "UserMicrosoftTeamWebHook"
            }
        }
    }

    private let secureStore: SecureStore
    private let keyValueStore: KeyValueStore

    public override convenience init() {
        self.init(secureStore: KeychainSecureStore(), keyValueStore: UserDefaultsKeyValueStore())
    }

    /// Injectable for tests (in-memory fakes).
    public init(secureStore: SecureStore, keyValueStore: KeyValueStore) {
        self.secureStore = secureStore
        self.keyValueStore = keyValueStore
        super.init()
    }

    // MARK: - Accessors (nil when unset)

    public var slackWebhook: String? {
        get { value(for: .slack) }
        set { setValue(newValue, for: .slack) }
    }
    public var teamsWebhook: String? {
        get { value(for: .teams) }
        set { setValue(newValue, for: .teams) }
    }

    private func value(for secret: Secret) -> String? {
        if let stored = try? secureStore.string(forAccount: secret.account, service: Self.service), !stored.isEmpty {
            return stored
        }
        let legacy = keyValueStore.string(forKey: secret.legacyDefaultsKey)
        return (legacy?.isEmpty == false) ? legacy : nil
    }

    private func setValue(_ value: String?, for secret: Secret) {
        do {
            if let value, !value.isEmpty {
                try secureStore.setString(value, forAccount: secret.account, service: Self.service)
            } else {
                try secureStore.removeItem(forAccount: secret.account, service: Self.service)
            }
            keyValueStore.removeObject(forKey: secret.legacyDefaultsKey)
        } catch {
            Self.log.error("Failed to store the \(secret.account, privacy: .public) webhook in the Keychain: \(String(describing: error), privacy: .public)")
        }
    }

    // MARK: - Migration

    /// Move any webhook secret still in `UserDefaults` into the Keychain, then delete the `UserDefaults` key.
    public func migrateFromUserDefaultsIfNeeded() {
        for secret in Secret.allCases {
            guard let legacy = keyValueStore.string(forKey: secret.legacyDefaultsKey), !legacy.isEmpty else {
                continue
            }
            if let existing = try? secureStore.string(forAccount: secret.account, service: Self.service), !existing.isEmpty {
                keyValueStore.removeObject(forKey: secret.legacyDefaultsKey)
                continue
            }
            do {
                try secureStore.setString(legacy, forAccount: secret.account, service: Self.service)
                keyValueStore.removeObject(forKey: secret.legacyDefaultsKey)
                Self.log.info("Migrated the \(secret.account, privacy: .public) webhook from UserDefaults to the Keychain.")
            } catch {
                Self.log.error("Could not migrate the \(secret.account, privacy: .public) webhook to the Keychain; leaving it in UserDefaults.")
            }
        }
    }
}
