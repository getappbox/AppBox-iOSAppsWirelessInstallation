import Foundation
import os

/// Sources the Dropbox app key: cached backend value when available, else the injected fallback (the composition root supplies the build's compiled-in key, generated from the gitignored `.env`) — so launch (which must configure SwiftyDropbox before any network call) never blocks, and the backend can rotate the key without an app release (alongside one that updates the `db-` URL scheme).
public final class DropboxAppKeyProvider {

    public static let cacheKey = "DropboxAppKey"
    private static let log = Logger(subsystem: "com.developerinsider.AppBox.core", category: "AppKey")

    private let store: KeyValueStore
    private let fallback: String

    public init(store: KeyValueStore, fallback: String) {
        self.store = store
        self.fallback = fallback
    }

    /// Synchronous — usable at launch, pre-network: the cached backend value or the fallback.
    public func cachedKey() -> String {
        if let cached = store.string(forKey: Self.cacheKey), !cached.isEmpty {
            return cached
        }
        return fallback
    }

    /// Fetch the key from the backend and cache it for the NEXT launch (SwiftyDropbox is already configured by the time this can run).
    public func refresh(using service: AppBoxServiceClient) async {
        do {
            let key = try await service.fetchDropboxAppKey()
            guard !key.isEmpty else { return }
            store.set(key, forKey: Self.cacheKey)
        } catch {
            Self.log.info("Dropbox app-key refresh failed (using cache/fallback): \(error.localizedDescription)")
        }
    }
}
