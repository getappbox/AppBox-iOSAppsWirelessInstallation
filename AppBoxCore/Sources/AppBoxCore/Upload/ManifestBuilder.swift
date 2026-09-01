import Foundation

/// The OTA install `manifest.plist` structure (the `itms-services://?action=download-manifest` format).
public struct OTAManifest: Codable, Equatable {
    public let items: [Item]

    public struct Item: Codable, Equatable {
        public let assets: [Asset]
        public let metadata: Metadata
    }

    public struct Asset: Codable, Equatable {
        public let kind: String
        public let url: String
    }

    public struct Metadata: Codable, Equatable {
        public let kind: String
        public let title: String
        public let bundleIdentifier: String
        public let bundleVersion: String

        enum CodingKeys: String, CodingKey {
            case kind, title
            case bundleIdentifier = "bundle-identifier"
            case bundleVersion = "bundle-version"
        }
    }
}

public enum ManifestBuilder {

    /// Builds the manifest for one build.
    public static func make(ipaShareableURL: String, name: String, identifier: String, version: String) -> OTAManifest {
        OTAManifest(items: [
            OTAManifest.Item(
                assets: [OTAManifest.Asset(kind: "software-package", url: ipaShareableURL)],
                metadata: OTAManifest.Metadata(kind: "software", title: name,
                                               bundleIdentifier: identifier, bundleVersion: version)
            )
        ])
    }

    /// XML-plist data for the manifest (what gets written to `manifest.plist` and uploaded).
    public static func plistData(for manifest: OTAManifest) throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        return try encoder.encode(manifest)
    }
}

