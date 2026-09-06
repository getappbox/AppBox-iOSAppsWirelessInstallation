import Foundation

/// Trivial, UI-free build/version surface for `AppBoxCore` — the module name and a cheap linked check.
public final class ABCoreBuildInfo: NSObject {

    /// Marketing version of the Core module, kept in sync with the app release line.
    public static let moduleName: String = "AppBoxCore"

    /// Returns true — a cheap way for the host targets to assert the module linked & loaded.
    public static func isLinked() -> Bool { true }
}
