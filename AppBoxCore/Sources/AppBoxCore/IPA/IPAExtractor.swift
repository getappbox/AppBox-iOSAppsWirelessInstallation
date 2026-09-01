import Foundation

/// Locations of the interesting files inside an extracted IPA (paths relative to the archive root).
public struct IPAPayloadLayout: Equatable {
    public let payloadAppPath: String        // e.g. "Payload/MyApp.app"
    public let infoPlistPath: String         // e.g. "Payload/MyApp.app/Info.plist"
    public let mobileProvisionPath: String?  // e.g. "Payload/MyApp.app/embedded.mobileprovision"
}

/// Pure logic to locate the `.app` payload, its `Info.plist`, and the embedded provisioning profile from a list of archive entry paths.
public enum ExtractedIPALocator {

    /// Returns the layout, or `nil` if no `.app` payload with an `Info.plist` is present.
    public static func locate(entries: [String]) -> IPAPayloadLayout? {
        guard let payloadApp = payloadAppPath(in: entries) else { return nil }

        let infoLower = (payloadApp + "/Info.plist").lowercased()
        let provisionLower = (payloadApp + "/embedded.mobileprovision").lowercased()

        guard let infoPlist = entries.first(where: { $0.lowercased() == infoLower }) else { return nil }
        let provision = entries.first(where: { $0.lowercased() == provisionLower })

        return IPAPayloadLayout(payloadAppPath: payloadApp, infoPlistPath: infoPlist, mobileProvisionPath: provision)
    }

    /// First entry whose path contains a `*.app` component, truncated to that component.
    private static func payloadAppPath(in entries: [String]) -> String? {
        for entry in entries where entry.lowercased().contains(".app") {
            let components = entry.components(separatedBy: "/")
            for (index, component) in components.enumerated()
            where component.count > 4 && component.lowercased().hasSuffix(".app") {
                return components[0...index].joined(separator: "/")
            }
        }
        return nil
    }
}

public enum IPAExtractionError: Error, Equatable {
    /// No `.app` payload (with an `Info.plist`) was found in the archive.
    case invalidIPA
}

/// Absolute URLs to the extracted IPA's payload and metadata files.
public struct ExtractedIPA: Equatable {
    public let workingDirectory: URL
    public let payloadAppURL: URL
    public let infoPlistURL: URL
    public let mobileProvisionURL: URL?
}

/// Unzips an IPA (via `ArchiveExtractor`) and resolves the payload / Info.plist / provisioning locations.
public final class IPAExtractor {

    private let archiveExtractor: ArchiveExtractor

    public init(archiveExtractor: ArchiveExtractor) {
        self.archiveExtractor = archiveExtractor
    }

    public func extract(ipaAt ipaURL: URL, to destination: URL) throws -> ExtractedIPA {
        let entries = try archiveExtractor.entries(ofArchiveAt: ipaURL)
        guard let layout = ExtractedIPALocator.locate(entries: entries) else {
            throw IPAExtractionError.invalidIPA
        }
        try archiveExtractor.extract(archiveAt: ipaURL, to: destination)
        return ExtractedIPA(
            workingDirectory: destination,
            payloadAppURL: destination.appendingPathComponent(layout.payloadAppPath),
            infoPlistURL: destination.appendingPathComponent(layout.infoPlistPath),
            mobileProvisionURL: layout.mobileProvisionPath.map { destination.appendingPathComponent($0) }
        )
    }
}
