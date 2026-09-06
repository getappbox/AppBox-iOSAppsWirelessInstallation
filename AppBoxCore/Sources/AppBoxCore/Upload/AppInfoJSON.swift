import Foundation

public struct ProvisioningJSON: Codable, Equatable {
    public var createdate: Double?
    public var expirationdata: Double?
    public var teamid: String?
    public var teamname: String?
    public var uuid: String?
    public var devicesudid: [String]?

    public var isEmpty: Bool {
        createdate == nil && expirationdata == nil && teamid == nil &&
        teamname == nil && uuid == nil && (devicesudid?.isEmpty ?? true)
    }
}

public struct AppVersionEntry: Codable, Equatable {
    public var name: String
    public var version: String
    public var build: String
    public var identifier: String
    public var manifestLink: String
    public var timestamp: Double
    public var ipaFileLink: String?
    public var minosversion: String?
    public var supporteddevice: String?
    public var buildtype: String?
    public var ipafilesize: Int?
    public var mobileprovision: ProvisioningJSON?
}

extension AppVersionEntry {
    /// Tolerant decoding: legacy / hand-edited `appinfo.json` entries may miss core fields — the ObjC reader used plain NSDictionary lookups and tolerated anything.
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        version = try container.decodeIfPresent(String.self, forKey: .version) ?? ""
        build = try container.decodeIfPresent(String.self, forKey: .build) ?? ""
        identifier = try container.decodeIfPresent(String.self, forKey: .identifier) ?? ""
        manifestLink = try container.decodeIfPresent(String.self, forKey: .manifestLink) ?? ""
        timestamp = try container.decodeIfPresent(Double.self, forKey: .timestamp) ?? 0
        ipaFileLink = try container.decodeIfPresent(String.self, forKey: .ipaFileLink)
        minosversion = try container.decodeIfPresent(String.self, forKey: .minosversion)
        supporteddevice = try container.decodeIfPresent(String.self, forKey: .supporteddevice)
        buildtype = try container.decodeIfPresent(String.self, forKey: .buildtype)
        ipafilesize = try container.decodeIfPresent(Int.self, forKey: .ipafilesize)
        mobileprovision = try container.decodeIfPresent(ProvisioningJSON.self, forKey: .mobileprovision)
    }
}

/// Inputs for one build's version entry (primitive values pulled from `IPAUploadInfo` + the user's preference flags by the caller).
public struct AppVersionInput {
    public var name: String
    public var version: String
    public var build: String
    public var identifier: String
    public var manifestLink: String
    public var timestamp: Double
    public var shareableIPALink: String

    public var includeIPALink: Bool
    public var includeDetails: Bool

    public var minOSVersion: String?
    public var supportedDevice: String?
    public var buildType: String?
    public var ipaFileSizeMB: Int?
    public var provisioningCreateDate: Date?
    public var provisioningExpirationDate: Date?
    public var teamId: String?
    public var teamName: String?
    public var provisioningUUID: String?
    public var provisionedDevices: [String]?

    public init(name: String, version: String, build: String, identifier: String,
                manifestLink: String, timestamp: Double, shareableIPALink: String,
                includeIPALink: Bool, includeDetails: Bool,
                minOSVersion: String? = nil, supportedDevice: String? = nil, buildType: String? = nil,
                ipaFileSizeMB: Int? = nil, provisioningCreateDate: Date? = nil,
                provisioningExpirationDate: Date? = nil, teamId: String? = nil, teamName: String? = nil,
                provisioningUUID: String? = nil, provisionedDevices: [String]? = nil) {
        self.name = name; self.version = version; self.build = build; self.identifier = identifier
        self.manifestLink = manifestLink; self.timestamp = timestamp; self.shareableIPALink = shareableIPALink
        self.includeIPALink = includeIPALink; self.includeDetails = includeDetails
        self.minOSVersion = minOSVersion; self.supportedDevice = supportedDevice; self.buildType = buildType
        self.ipaFileSizeMB = ipaFileSizeMB; self.provisioningCreateDate = provisioningCreateDate
        self.provisioningExpirationDate = provisioningExpirationDate; self.teamId = teamId
        self.teamName = teamName; self.provisioningUUID = provisioningUUID
        self.provisionedDevices = provisionedDevices
    }
}

/// Masks provisioned-device UDIDs the way the install page expects (hide the middle).
public enum DeviceUDIDMasker {
    public static func mask(_ udid: String) -> String? {
        let count = udid.count
        if count > 30 { return replacing(udid, location: 10, length: 20) }
        if count > 20 { return replacing(udid, location: 8, length: 5) }
        return nil
    }

    private static func replacing(_ string: String, location: Int, length: Int) -> String {
        let start = string.index(string.startIndex, offsetBy: location)
        let end = string.index(start, offsetBy: length)
        return string.replacingCharacters(in: start..<end, with: ".....")
    }
}

public enum AppInfoJSON {

    /// Build a `latestVersion` entry from the upload info, honoring the display flags.
    public static func makeEntry(_ input: AppVersionInput) -> AppVersionEntry {
        var entry = AppVersionEntry(name: input.name, version: input.version, build: input.build,
                                    identifier: input.identifier, manifestLink: input.manifestLink,
                                    timestamp: input.timestamp)
        if input.includeIPALink {
            entry.ipaFileLink = input.shareableIPALink
        }
        if input.includeDetails {
            entry.minosversion = input.minOSVersion
            entry.supporteddevice = input.supportedDevice
            entry.buildtype = input.buildType
            entry.ipafilesize = input.ipaFileSizeMB

            var provisioning = ProvisioningJSON()
            provisioning.createdate = input.provisioningCreateDate?.timeIntervalSince1970
            provisioning.expirationdata = input.provisioningExpirationDate?.timeIntervalSince1970
            provisioning.teamid = input.teamId
            provisioning.teamname = input.teamName
            provisioning.uuid = input.provisioningUUID
            if let devices = input.provisionedDevices {
                provisioning.devicesudid = devices.compactMap(DeviceUDIDMasker.mask)
            }
            if !provisioning.isEmpty {
                entry.mobileprovision = provisioning
            }
        }
        return entry
    }

    /// Append `entry` to the history, resetting it first unless previous versions are kept.
    public static func updatedHistory(_ history: [AppVersionEntry], adding entry: AppVersionEntry,
                                      keepPreviousVersions: Bool) -> [AppVersionEntry] {
        var versions = keepPreviousVersions ? history : []
        versions.append(entry)
        return versions
    }

    /// Outcome of removing one build's version from the history.
    public enum VersionRemoval: Equatable {
        case updated(versions: [AppVersionEntry], latestVersion: AppVersionEntry)
        case historyEmptied
    }

    /// Remove the (first) version whose `manifestLink` matches `link`.
    public static func removingVersion(withManifestLink link: String,
                                       from versions: [AppVersionEntry],
                                       latestVersion: AppVersionEntry?) -> VersionRemoval {
        var remaining = versions
        if let index = remaining.firstIndex(where: { $0.manifestLink == link }) {
            remaining.remove(at: index)
        }
        guard let last = remaining.last else { return .historyEmptied }
        let newLatest = (latestVersion != nil && latestVersion!.manifestLink != link) ? latestVersion! : last
        return .updated(versions: remaining, latestVersion: newLatest)
    }
}
