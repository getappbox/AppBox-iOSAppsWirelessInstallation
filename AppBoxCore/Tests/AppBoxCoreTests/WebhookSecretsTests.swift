import XCTest
@testable import AppBoxCore

/// A `SecureStore` whose writes always fail — used to prove a failed Keychain write never loses the legacy `UserDefaults` value during migration.
private final class FailingSecureStore: SecureStore {
    func data(forAccount account: String, service: String) throws -> Data? { nil }
    func set(_ data: Data, forAccount account: String, service: String) throws { throw SecureStoreError.keychain(status: -1) }
    func removeItem(forAccount account: String, service: String) throws {}
    func accounts(forService service: String) throws -> [String] { [] }
    func removeAllItems(forService service: String) throws {}
}

final class WebhookSecretsTests: XCTestCase {

    private let slackKey = "UserSlackChannel"
    private let teamsKey = "UserMicrosoftTeamWebHook"

    private func makeSecrets(_ secure: SecureStore = InMemorySecureStore(),
                             _ defaults: InMemoryKeyValueStore = InMemoryKeyValueStore()) -> WebhookSecrets {
        WebhookSecrets(secureStore: secure, keyValueStore: defaults)
    }

    func testSetAndGetRoundTrip_perSecret() {
        let secrets = makeSecrets()
        secrets.slackWebhook = "https://hooks.slack/s"
        secrets.teamsWebhook = "https://teams/t"
        XCTAssertEqual(secrets.slackWebhook, "https://hooks.slack/s")
        XCTAssertEqual(secrets.teamsWebhook, "https://teams/t")
    }

    func testEmptyOrNilSetRemovesTheSecret() {
        let secrets = makeSecrets()
        secrets.slackWebhook = "https://hooks.slack/s"
        secrets.slackWebhook = ""
        XCTAssertNil(secrets.slackWebhook)
        secrets.teamsWebhook = "https://teams/t"
        secrets.teamsWebhook = nil
        XCTAssertNil(secrets.teamsWebhook)
    }

    func testMigration_movesSecretsIntoKeychainAndRemovesDefaultsKeys() {
        let defaults = InMemoryKeyValueStore()
        defaults.set("https://hooks.slack/legacy", forKey: slackKey)
        defaults.set("https://teams/legacy", forKey: teamsKey)
        let secrets = makeSecrets(InMemorySecureStore(), defaults)

        secrets.migrateFromUserDefaultsIfNeeded()

        XCTAssertEqual(secrets.slackWebhook, "https://hooks.slack/legacy")
        XCTAssertEqual(secrets.teamsWebhook, "https://teams/legacy")
        XCTAssertNil(defaults.string(forKey: slackKey))
        XCTAssertNil(defaults.string(forKey: teamsKey))
    }

    func testMigration_isIdempotent() {
        let defaults = InMemoryKeyValueStore()
        defaults.set("https://hooks.slack/legacy", forKey: slackKey)
        let secrets = makeSecrets(InMemorySecureStore(), defaults)

        secrets.migrateFromUserDefaultsIfNeeded()
        secrets.migrateFromUserDefaultsIfNeeded()
        XCTAssertEqual(secrets.slackWebhook, "https://hooks.slack/legacy")
        XCTAssertNil(defaults.string(forKey: slackKey))
    }

    func testMigration_failedKeychainWriteKeepsTheDefaultsValue() {
        let defaults = InMemoryKeyValueStore()
        defaults.set("https://hooks.slack/legacy", forKey: slackKey)
        let secrets = makeSecrets(FailingSecureStore(), defaults)

        secrets.migrateFromUserDefaultsIfNeeded()

        XCTAssertEqual(defaults.string(forKey: slackKey), "https://hooks.slack/legacy")
        XCTAssertEqual(secrets.slackWebhook, "https://hooks.slack/legacy")
    }

    func testGetterFallsBackToLegacyValueBeforeMigration() {
        let defaults = InMemoryKeyValueStore()
        defaults.set("https://hooks.slack/legacy", forKey: slackKey)
        let secrets = makeSecrets(InMemorySecureStore(), defaults)
        XCTAssertEqual(secrets.slackWebhook, "https://hooks.slack/legacy")
    }
}
