import Foundation
import SwiftyDropbox

/// A reference to a remote Dropbox file: just the bits the upload pipeline needs after a write or a revision lookup (the path to share/download, and the revision to update in place).
public final class RemoteFileRef: NSObject {
    public let pathDisplay: String
    public let rev: String

    public init(pathDisplay: String, rev: String) {
        self.pathDisplay = pathDisplay
        self.rev = rev
    }
}

/// Dropbox transport over the SwiftyDropbox SDK.
public final class DropboxTransport: NSObject {

    public static let shared = DropboxTransport()

    /// NSError domain for transport failures.
    public static let errorDomain = "AppBoxCore.DropboxTransport"
    /// userInfo key holding the `ABUploadFailureKind` raw value (so the retry policy can read it).
    static let failureKindKey = "ABFailureKind"
    /// userInfo key holding a `Bool` — true when the failure means the user must re-authenticate.
    static let authErrorKey = "ABIsAuthError"

    private func client() -> DropboxClient? { DropboxClientsManager.authorizedClient }

    private func onMain(_ block: @escaping () -> Void) { DispatchQueue.main.async(execute: block) }

    // MARK: - Upload

    /// Single-shot upload of a local file.
    // MARK: - Shareable links

    /// Create a shared link for `path` and return it normalized for AppBox's dashboard (the `dl` query param stripped — see `normalizedShareURL`).
    /// Fetch an existing shared link for `path` (used on a 409 conflict when one already exists).
    // MARK: - Revisions / download / delete

    /// The latest live revision of `path`, or nil if the file doesn't exist / was deleted.
    public func download(fromPath path: String, toLocalURL localURL: URL, completion: @escaping (NSError?) -> Void) {
        guard let client = client() else { return failNotAuthenticated { _, e in completion(e) } }
        client.files.download(path: path, overwrite: true, destination: localURL)
            .response(queue: .main) { result, error in
                completion(result != nil ? nil : DropboxTransport.nsError(from: error))
            }
    }

    public func delete(atPath path: String, completion: @escaping (NSError?) -> Void) {
        guard let client = client() else { return failNotAuthenticated { _, e in completion(e) } }
        client.files.deleteV2(path: path)
            .response(queue: .main) { result, error in
                completion(result != nil ? nil : DropboxTransport.nsError(from: error))
            }
    }

    // MARK: - Account

    /// The signed-in account's email + display name (for the account menu / `registerUserId`).
    public func currentAccount(completion: @escaping (String?, String?, NSError?) -> Void) {
        guard let client = client() else { return onMain { completion(nil, nil, DropboxTransport.notAuthenticatedError()) } }
        client.users.getCurrentAccount()
            .response(queue: .main) { account, error in
                if let account {
                    completion(account.email, account.name.displayName, nil)
                } else {
                    completion(nil, nil, DropboxTransport.nsError(from: error))
                }
            }
    }

    /// Used / allocated Dropbox space in **megabytes** (mirrors the old menu math).
    public func spaceUsage(completion: @escaping (Int, Int, NSError?) -> Void) {
        guard let client = client() else { return onMain { completion(0, 0, DropboxTransport.notAuthenticatedError()) } }
        client.users.getSpaceUsage()
            .response(queue: .main) { usage, error in
                if let usage {
                    let usedMB = Int(usage.used / (1024 * 1024))
                    var allocatedMB = 0
                    if case .individual(let individual) = usage.allocation {
                        allocatedMB = Int(individual.allocated / (1024 * 1024))
                    }
                    completion(usedMB, allocatedMB, nil)
                } else {
                    completion(0, 0, DropboxTransport.nsError(from: error))
                }
            }
    }

    // MARK: - Error helpers

    /// Read the retry classification an upload error carries, for `ABUploadRetryPolicy`.
    public static func failureKind(for error: NSError?) -> ABUploadFailureKind {
        guard let raw = error?.userInfo[failureKindKey] as? Int,
              let kind = ABUploadFailureKind(rawValue: raw) else { return .none }
        return kind
    }

    /// Whether an error means the Dropbox session is no longer valid (re-login required).
    public static func isAuthError(_ error: NSError?) -> Bool {
        (error?.userInfo[authErrorKey] as? Bool) ?? false
    }

    // MARK: - Private helpers

    private func failNotAuthenticated(_ completion: @escaping (RemoteFileRef?, NSError?) -> Void) {
        onMain { completion(nil, DropboxTransport.notAuthenticatedError()) }
    }

    static func notAuthenticatedError() -> NSError {
        nsError(message: "You're not signed in to Dropbox. Please log in again.", kind: .other, isAuth: true)
    }

    /// Normalize a Dropbox share URL for AppBox: drop the `dl` query parameter, keep everything else (notably the `rlkey` in the modern `scl/fi` links).
    static func normalizedShareURL(_ raw: String) -> String {
        guard var components = URLComponents(string: raw) else {
            return fallbackStripDL(raw)
        }
        if let items = components.queryItems {
            let filtered = items.filter { $0.name != "dl" }
            components.queryItems = filtered.isEmpty ? nil : filtered
        }
        return components.string ?? fallbackStripDL(raw)
    }

    private static func fallbackStripDL(_ raw: String) -> String {
        for suffix in ["?dl=0", "?dl=1", "&dl=0", "&dl=1"] where raw.hasSuffix(suffix) {
            return String(raw.dropLast(suffix.count))
        }
        return raw
    }

    // MARK: Error mapping

    static func nsError(message: String, kind: ABUploadFailureKind, isAuth: Bool) -> NSError {
        NSError(domain: errorDomain, code: kind.rawValue, userInfo: [
            NSLocalizedDescriptionKey: message,
            failureKindKey: kind.rawValue,
            authErrorKey: isAuth,
        ])
    }

    /// Collapse a SwiftyDropbox `CallError` into an `NSError` that carries a user-facing message, the retry classification, and an auth flag.
    static func nsError<E>(from callError: CallError<E>?) -> NSError {
        guard let callError else {
            return nsError(message: "Something went wrong. Please try again.", kind: .other, isAuth: false)
        }
        let (kind, isAuth) = classify(callError)
        let message: String
        switch kind {
        case .connectivity:
            message = "No internet connection. Please check your connection and try again."
        case .retryableServer:
            message = "Dropbox had a temporary problem. Please try again."
        case .other where isAuth:
            message = "Your Dropbox session has expired. Please log in again."
        case .other, .none:
            message = "Dropbox request failed: \(callError)"
        }
        return nsError(message: message, kind: kind, isAuth: isAuth)
    }

    private static func classify<E>(_ callError: CallError<E>) -> (ABUploadFailureKind, Bool) {
        switch callError {
        case .authError, .accessError:
            return (.other, true)
        case .rateLimitError, .internalServerError:
            return (.retryableServer, false)
        case .httpError(let code, _, _):
            if let code, (500..<600).contains(code) { return (.retryableServer, false) }
            return (.other, false)
        case .clientError(let clientError):
            return (isConnectivity(clientError) ? .connectivity : .retryableServer, false)
        case .reconnectionError(let underlying):
            return (UploadRetryPolicy.isConnectivityError(underlying) ? .connectivity : .retryableServer, false)
        case .routeError, .badInputError, .serializationError:
            return (.other, false)
        }
    }

    private static func isConnectivity(_ clientError: ClientError) -> Bool {
        switch clientError {
        case .urlSessionError(let underlying), .other(let underlying):
            return UploadRetryPolicy.isConnectivityError(underlying)
        default:
            return false
        }
    }
}
