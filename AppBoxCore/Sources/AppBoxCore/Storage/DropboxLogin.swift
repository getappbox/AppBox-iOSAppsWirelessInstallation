#if canImport(AppKit)
import AppKit
import Foundation
import SwiftyDropbox

/// The one piece of the Dropbox transport that genuinely needs AppKit: the interactive OAuth flow.
public final class DropboxLogin: NSObject {

    /// Scopes AppBox needs: read the account (email/name + space usage), read/write file contents (upload/download IPAs + appinfo.json), and create/list shared links.
    static let scopes = [
        "account_info.read",
        "files.content.write",
        "files.content.read",
        "sharing.write",
        "sharing.read",
    ]

    /// Present the Dropbox authorization flow from `controller`.
    public static func present(from controller: NSViewController) {
        let scopeRequest = ScopeRequest(scopeType: .user, scopes: scopes, includeGrantedScopes: false)
        DropboxClientsManager.authorizeFromControllerV2(
            sharedApplication: NSApplication.shared,
            controller: controller,
            loadingStatusDelegate: nil,
            openURL: { url in NSWorkspace.shared.open(url) },
            scopeRequest: scopeRequest
        )
    }
}
#endif
