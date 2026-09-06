import Foundation

/// Builds the AppBox install-page URL for a Dropbox `appinfo.json` share link.
public enum InstallLink {
    public static let defaultBase = "https://web.getappbox.com"

    /// The install-page URL for a Dropbox share URL, or `nil` if `dropboxShareURL` isn't a dropbox.com link (caller should then keep whatever link it already has).
    public static func make(fromDropboxShareURL dropboxShareURL: URL, base: String = defaultBase) -> URL? {
        let absolute = dropboxShareURL.absoluteString
        guard let range = absolute.range(of: "dropbox.com") else { return nil }
        let sharePath = escapedForQueryValue(String(absolute[range.upperBound...]))
        return URL(string: "\(base)?url=\(sharePath)")
    }

    static func escapedForQueryValue(_ value: String) -> String {
        value.replacingOccurrences(of: "%", with: "%25")
            .replacingOccurrences(of: "&", with: "%26")
            .replacingOccurrences(of: "#", with: "%23")
    }
}
