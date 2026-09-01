import Foundation
import SwiftyDropbox

/// Non-UI Dropbox session management on SwiftyDropbox configure the SDK, handle the OAuth redirect, report auth state, sign out, and vend a `DropboxStorageProvider`.
public final class DropboxSession: NSObject {

    /// SwiftyDropbox's `setupWithAppKeyDesktop` installs the shared OAuth manager and `precondition`s that it is only ever called once per process — a second call crashes.
    private static var isConfigured = false

    /// Call at launch with the Dropbox app key (`DropboxAppKeyProvider.cachedKey()`).
    public static func setup(appKey: String) {
        guard !isConfigured else { return }
        isConfigured = true
        DropboxTokenMigration.migrateIfNeeded()
        DropboxClientsManager.setupWithAppKeyDesktop(appKey)
    }

    public static var isAuthorized: Bool {
        DropboxClientsManager.authorizedClient != nil
    }

    /// Handle the `db-<appKey>://` OAuth redirect.
    @discardableResult
    public static func handleRedirect(_ url: URL, completion: @escaping (Bool, String?) -> Void) -> Bool {
        DropboxClientsManager.handleRedirectURL(url, includeBackgroundClient: false) { result in
            switch result {
            case .success:
                completion(true, nil)
            case .cancel:
                completion(false, "Dropbox authorization was cancelled.")
            case .error(_, let description):
                completion(false, description ?? "Dropbox authorization failed.")
            case .none:
                break
            }
        }
    }

    public static func signOut() {
        DropboxClientsManager.unlinkClients()
    }

    /// The logged-in user's Dropbox access token, refreshed when near expiry — used to authenticate to the AppBox backend (mail / short links), which verifies it against Dropbox.
    public static func currentAccessToken() async -> String? {
        guard let provider = DropboxClientsManager.authorizedClient?.accessTokenProvider else {
            return nil
        }
        return await withCheckedContinuation { continuation in
            provider.refreshAccessTokenIfNecessary { _ in
                continuation.resume(returning: provider.accessToken)
            }
        }
    }

    /// A `StorageProvider` backed by the currently authorized Dropbox client.
    public static func makeProvider(chunkSizeBytes: Int = 100 * 1024 * 1024,
                                    reachability: Reachability? = nil) -> DropboxStorageProvider {
        DropboxStorageProvider(clientProvider: { DropboxClientsManager.authorizedClient },
                               chunkSizeBytes: chunkSizeBytes, reachability: reachability)
    }
}
