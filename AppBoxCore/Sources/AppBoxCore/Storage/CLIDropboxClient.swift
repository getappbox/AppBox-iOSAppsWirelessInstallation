import Foundation
import SwiftyDropbox

/// One-time, process-wide setup of `DropboxClientsManager` for the CLI.
public enum CLIDropboxClient {
    private static var configured = false

    /// Installs the OAuth manager with the CLI-safe Keychain store (idempotent).
    public static func ensureConfigured(appKey: String,
                                        secureStorage: SecureStorageAccess = CLISecureStorageAccess(service: "com.developerinsider.AppBox.dropbox.authv2")) {
        if !configured {
            configured = true
            DropboxClientsManager.setupWithAppKeyDesktop(appKey, secureStorageAccess: secureStorage)
        }
    }
}
