import Foundation

// MARK: - DateProvider

/// Abstraction over "the current time" (production: `Date()`).
public protocol DateProvider: AnyObject {
    func now() -> Date
}

// MARK: - Reachability

/// Abstraction over network reachability (production: `NWPathMonitor`, wired in a later phase).
public protocol Reachability: AnyObject {
    var isConnected: Bool { get }
}

// MARK: - ProgressReporter

/// Coarse stages of an upload, surfaced to whatever UI is driving it.
public enum UploadStage: Equatable, Sendable {
    case preparing
    case extracting
    case uploading
    case creatingLink
    case finalizing
    case completed
    case failed
}

/// UI-agnostic sink for upload progress.
public protocol ProgressReporter: AnyObject {
    /// - stage: the coarse phase the upload is in.
    func report(stage: UploadStage, message: String?, fractionCompleted: Double?)
}

/// A no-op `ProgressReporter` for contexts that don't surface progress (and as a safe default).
public final class NullProgressReporter: ProgressReporter {
    public init() {}
    public func report(stage: UploadStage, message: String?, fractionCompleted: Double?) {}
}
