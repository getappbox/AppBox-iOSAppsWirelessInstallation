import Foundation

/// Version-string extraction and comparison.
public enum VersionCompare {

    /// Extracts a dotted numeric version from arbitrary text (e.g.
    public static func extractVersion(from input: String?) -> String {
        guard let input else { return "0" }
        var version = ""
        for character in input {
            if character >= "0" && character <= "9" {
                version.append(character)
            } else if character == "." && !version.isEmpty {
                version.append(character)
            } else if !version.isEmpty {
                break
            }
        }
        while version.hasSuffix(".") {
            version.removeLast()
        }
        return version.isEmpty ? "0" : version
    }

    /// True if `latest` represents a newer version than `current` (numeric comparison of the extracted version strings, like `NSString.compare(_:options: .numeric)`).
    public static func isUpdateAvailable(latest: String?, current: String?) -> Bool {
        let latestVersion = extractVersion(from: latest)
        let currentVersion = extractVersion(from: current)
        return latestVersion.compare(currentVersion, options: .numeric) == .orderedDescending
    }
}

public final class ABVersionCompare: NSObject {
    public static func extractVersion(_ input: String?) -> String {
        VersionCompare.extractVersion(from: input)
    }

    public static func isUpdateAvailable(latest: String?, current: String?) -> Bool {
        VersionCompare.isUpdateAvailable(latest: latest, current: current)
    }
}
