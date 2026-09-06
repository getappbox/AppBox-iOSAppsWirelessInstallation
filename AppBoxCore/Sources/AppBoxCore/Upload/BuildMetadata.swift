//
//  BuildMetadata.swift
//  AppBoxCore
//

import Foundation

/// The build fields AppBox reads out of an IPA's `Info.plist`.
public struct BuildMetadata: Equatable, Sendable {
    public let name: String
    public let version: String
    public let build: String
    public let identifier: String
    public let minimumOSVersion: String?
    public let supportedDevice: String

    public init(name: String, version: String, build: String, identifier: String,
                minimumOSVersion: String?, supportedDevice: String) {
        self.name = IPAName.stripSpaces(name)
        self.version = version
        self.build = build
        self.identifier = identifier
        self.minimumOSVersion = minimumOSVersion
        self.supportedDevice = supportedDevice
    }

    /// Returns nil when any of the four required keys is missing, which is the old `isValidInfoPlist` check.
    public init?(infoPlist: [AnyHashable: Any]) {
        guard let name = infoPlist["CFBundleName"] as? String,
              let build = infoPlist["CFBundleVersion"] as? String,
              let identifier = infoPlist["CFBundleIdentifier"] as? String,
              let version = infoPlist["CFBundleShortVersionString"] as? String else {
            return nil
        }
        self.init(name: name,
                  version: version,
                  build: build,
                  identifier: identifier,
                  minimumOSVersion: infoPlist["MinimumOSVersion"] as? String,
                  supportedDevice: IPADeviceFamily.describe((infoPlist["UIDeviceFamily"] as? [NSNumber])?.map(\.intValue)))
    }

    /// Reads and parses the `Info.plist` an `IPAExtractor` produced.
    public static func read(fromInfoPlistAt url: URL) -> BuildMetadata? {
        guard let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil),
              let dictionary = plist as? [AnyHashable: Any] else {
            return nil
        }
        return BuildMetadata(infoPlist: dictionary)
    }
}

/// Where a build's files land in the storage provider.
public struct BuildRemotePaths: Equatable, Sendable {
    public let bundleDirectory: String
    public let buildDirectory: String
    public let ipa: RemotePath
    public let manifest: RemotePath
    public let appInfo: RemotePath

    /// Derives the layout used since v3: `<bundleDirectory>/<name>-ver<version>(<build>)-<uuid>/`, with `appinfo.json` hoisted to the bundle directory when the short link must stay stable.
    public init(metadata: BuildMetadata, uuid: String, bundleDirectory: String? = nil, keepSameLink: Bool) {
        let requested = (bundleDirectory?.isEmpty == false) ? bundleDirectory! : "/\(metadata.identifier)"
        let validBundleDirectory = IPAName.sanitizedPath(requested)
        let validName = IPAName.sanitizedPathComponent(metadata.name)
        let folder = validName
            + "-ver\(IPAName.sanitizedPathComponent(metadata.version))"
            + "(\(IPAName.sanitizedPathComponent(metadata.build)))"
            + "-\(IPAName.sanitizedPathComponent(uuid))"
        let buildDirectory = (validBundleDirectory as NSString).appendingPathComponent(folder)

        self.bundleDirectory = validBundleDirectory
        self.buildDirectory = buildDirectory
        self.ipa = RemotePath(path: "\(buildDirectory)/\(validName).ipa")
        self.manifest = RemotePath(path: "\(buildDirectory)/manifest.plist")
        self.appInfo = RemotePath(path: keepSameLink
                                  ? "\(validBundleDirectory)/appinfo.json"
                                  : "\(buildDirectory)/appinfo.json")
    }
}

/// Writes the share URLs to `~/.appbox_share_value.json` so a CI step can read them back.
public enum ShareURLExport {
    public static let fileName = ".appbox_share_value.json"

    @discardableResult
    public static func write(shareURL: URL?, ipaURL: URL?, manifestURL: URL?,
                             toDirectory directory: String = NSHomeDirectory()) -> Bool {
        let values = [
            "APPBOX_SHARE_URL": shareURL?.absoluteString ?? "",
            "APPBOX_IPA_URL": ipaURL?.absoluteString ?? "",
            "APPBOX_MANIFEST_URL": manifestURL?.absoluteString ?? ""
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: values, options: .prettyPrinted) else {
            return false
        }
        let path = (directory as NSString).appendingPathComponent(fileName)
        try? FileManager.default.removeItem(atPath: path)
        return (try? data.write(to: URL(fileURLWithPath: path), options: .atomic)) != nil
    }
}
