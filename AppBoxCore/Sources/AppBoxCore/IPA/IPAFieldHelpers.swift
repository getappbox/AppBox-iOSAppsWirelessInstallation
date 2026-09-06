import Foundation

/// Pure helpers for deriving display/URL-safe names and the supported-device string.
public enum IPAName {

    /// Removes spaces from a build name (matches the old `setName:`).
    public static func stripSpaces(_ name: String) -> String {
        name.replacingOccurrences(of: " ", with: "")
    }

    /// Keeps only characters allowed in a URL query component, falling back to `"AppBox"` when the result would be empty (matches the old `validURLString:`).
    public static func sanitizedForURL(_ string: String?) -> String {
        guard let string else { return "AppBox" }
        let allowed = CharacterSet.urlQueryAllowed
        let filtered = String(String.UnicodeScalarView(string.unicodeScalars.filter { allowed.contains($0) }))
        return filtered.isEmpty ? "AppBox" : filtered
    }

    /// Characters that are legal in a URL query but must not survive into a single remote path segment
    private static let pathComponentSeparators = CharacterSet(charactersIn: "/?")

    /// One path segment (app name, version, build, uuid): `sanitizedForURL` minus the characters that would restructure the path.
    public static func sanitizedPathComponent(_ string: String?) -> String {
        let sanitized = sanitizedForURL(string)
        let filtered = String(String.UnicodeScalarView(
            sanitized.unicodeScalars.filter { !pathComponentSeparators.contains($0) }))
        return filtered.isEmpty ? "AppBox" : filtered
    }

    /// A whole path: each segment sanitized as a segment, so `/` keeps its structural meaning and nothing else can introduce more of it.
    public static func sanitizedPath(_ string: String?) -> String {
        guard let string, !string.isEmpty else { return "AppBox" }
        let sanitized = string.components(separatedBy: "/")
            .map { $0.isEmpty ? "" : sanitizedPathComponent($0) }
            .joined(separator: "/")
        return sanitized.isEmpty || sanitized == "/" ? "AppBox" : sanitized
    }
}

public enum IPADeviceFamily {

    /// Maps an Info.plist `UIDeviceFamily` value to a human name.
    public static func name(for value: Int) -> String? {
        switch value {
        case 1: return "iPhone"
        case 2: return "iPad"
        case 3: return "Apple TV"
        case 4: return "Apple Watch"
        case 6: return "Mac"
        case 7: return "Apple Vision Pro"
        default: return nil
        }
    }

    /// Maps a `UIDeviceFamily` array to a display string, e.g.
    public static func describe(_ deviceFamily: [Int]?) -> String {
        guard let deviceFamily else { return "" }
        return deviceFamily.compactMap(name(for:)).joined(separator: " and ")
    }
}

public final class ABIPAInfo: NSObject {
    public static func sanitizedURLString(_ string: String?) -> String {
        IPAName.sanitizedForURL(string)
    }

    public static func stripSpaces(_ name: String) -> String {
        IPAName.stripSpaces(name)
    }

    public static func supportedDevice(fromDeviceFamily family: [NSNumber]?) -> String {
        IPADeviceFamily.describe(family?.map(\.intValue))
    }
}
