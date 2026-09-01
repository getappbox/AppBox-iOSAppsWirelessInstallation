import Foundation

/// Detects whether AppBox was installed via the Homebrew `appbox` cask, by checking the cask directories for Apple-silicon and Intel Homebrew prefixes.
public struct HomebrewDetector {

    /// Caskroom paths checked, in order: Apple silicon, then Intel.
    public static let caskPaths = [
        "/opt/homebrew/Caskroom/appbox",
        "/usr/local/Caskroom/appbox"
    ]

    private let fileSystem: FileSystem

    public init(fileSystem: FileSystem) {
        self.fileSystem = fileSystem
    }

    public var isInstalled: Bool {
        HomebrewDetector.caskPaths.contains { fileSystem.fileExists(at: URL(fileURLWithPath: $0)) }
    }
}

public final class ABHomebrewDetector: NSObject {
    public static func isInstalledViaHomebrew() -> Bool {
        HomebrewDetector(fileSystem: FileManagerFileSystem()).isInstalled
    }
}
