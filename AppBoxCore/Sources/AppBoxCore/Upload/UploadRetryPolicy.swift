import Foundation

/// What to do after an upload chunk/request fails.
public enum RetryDecision: Equatable {
    /// Retry now (the caller increments the retry count).
    case retry
    /// The network path is down — stop and resume when connectivity returns.
    case pauseUntilOnline
    /// Give up and surface the error.
    case fail
}

/// Provider-agnostic classification of an upload failure, so the retry rule doesn't depend on a specific SDK's error type.
public enum UploadFailureKind: Equatable {
    /// The network path is unavailable (e.g.
    case connectivity
    /// A transient server/client-side error that's worth retrying while online (maps the old `DBRequestErrorClient` / `DBRequestErrorInternalServer`, rate limits, 5xx).
    case retryableServer
    /// Anything else — not retryable (auth, route/validation errors, …).
    case other
}

/// Pure retry-decision logic.
public enum UploadRetryPolicy {

    /// Mirrors `abOnErrorMaxRetryCount`.
    public static let maxRetryCount = 3

    /// Decide what to do given the failure, how many retries have already happened, and whether the network is currently reachable.
    public static func decide(failure: UploadFailureKind?,
                              retryCount: Int,
                              isConnected: Bool,
                              maxRetryCount: Int = maxRetryCount) -> RetryDecision {
        guard let failure else { return .fail }

        if failure == .connectivity && !isConnected {
            return .pauseUntilOnline
        }

        if retryCount < maxRetryCount && isConnected &&
            (failure == .connectivity || failure == .retryableServer) {
            return .retry
        }

        return .fail
    }

    /// NSURLError codes meaning the network path is unavailable (mirror of the old `+isConnectivityError:`).
    public static func isConnectivityError(_ error: Error?) -> Bool {
        guard let error else { return false }
        let nsError = error as NSError
        guard nsError.domain == NSURLErrorDomain else { return false }
        let connectivityCodes: Set<Int> = [
            NSURLErrorNotConnectedToInternet,
            NSURLErrorNetworkConnectionLost,
            NSURLErrorCannotConnectToHost,
            NSURLErrorCannotFindHost,
            NSURLErrorDNSLookupFailed,
            NSURLErrorTimedOut,
            NSURLErrorDataNotAllowed,
            NSURLErrorInternationalRoamingOff
        ]
        return connectivityCodes.contains(nsError.code)
    }
}

public enum ABUploadFailureKind: Int {
    case none = 0
    case connectivity = 1
    case retryableServer = 2
    case other = 3
}

public extension UploadFailureKind {
    /// Classify a `StorageError` for the retry policy (used once the pipeline runs on `StorageProvider`): transient transport → connectivity; server/rate-limit → retryableServer; everything else → other.
    init(_ storageError: StorageError) {
        switch storageError {
        case .network:
            self = .connectivity
        case .server, .rateLimited:
            self = .retryableServer
        case .notAuthenticated, .authenticationFailed, .notFound, .conflict, .cancelled, .unknown:
            self = .other
        }
    }
}
