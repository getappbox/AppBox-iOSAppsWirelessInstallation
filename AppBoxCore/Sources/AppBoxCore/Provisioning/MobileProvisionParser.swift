import Foundation

/// Distribution build types, matching the `BuildType*` string constants from the code.
public enum BuildType {
    public static let unknown = "unknown"
    public static let adHoc = "ad-hoc"
    public static let package = "package"
    public static let appStore = "app-store"
    public static let enterprise = "enterprise"
    public static let development = "development"
    public static let developerId = "developer-id"
}

/// Parsed contents of an embedded `.mobileprovision` profile.
public struct MobileProvisionInfo: Equatable {
    public let isValid: Bool
    public let uuid: String?
    public let teamId: String?
    public let teamName: String?
    public let buildType: String?
    public let createDate: Date?
    public let expirationDate: Date?
    public let provisionedDevices: [String]?

    public static let invalid = MobileProvisionInfo(
        isValid: false, uuid: nil, teamId: nil, teamName: nil,
        buildType: nil, createDate: nil, expirationDate: nil, provisionedDevices: nil
    )

    public init(isValid: Bool, uuid: String?, teamId: String?, teamName: String?, buildType: String?,
                createDate: Date?, expirationDate: Date?, provisionedDevices: [String]?) {
        self.isValid = isValid
        self.uuid = uuid
        self.teamId = teamId
        self.teamName = teamName
        self.buildType = buildType
        self.createDate = createDate
        self.expirationDate = expirationDate
        self.provisionedDevices = provisionedDevices
    }
}

/// Parses a `.mobileprovision` file.
public enum MobileProvisionParser {

    /// Parse the raw bytes of a `.mobileprovision` file.
    public static func parse(data: Data) -> MobileProvisionInfo {
        guard let binaryString = String(data: data, encoding: .isoLatin1),
              let start = binaryString.range(of: "<plist"),
              let end = binaryString.range(of: "</plist>", range: start.lowerBound..<binaryString.endIndex)
        else {
            return .invalid
        }

        let plistString = String(binaryString[start.lowerBound..<end.upperBound])
        guard let plistData = plistString.data(using: .isoLatin1),
              let dict = (try? PropertyListSerialization.propertyList(from: plistData, options: [], format: nil)) as? [String: Any]
        else {
            return .invalid
        }
        return makeInfo(from: dict)
    }

    /// Read a `.mobileprovision` file through the injected file system, then parse it.
    public static func parse(contentsOf url: URL, fileSystem: FileSystem) -> MobileProvisionInfo {
        guard fileSystem.fileExists(at: url), let data = try? fileSystem.read(contentsOf: url) else {
            return .invalid
        }
        return parse(data: data)
    }

    private static func makeInfo(from dict: [String: Any]) -> MobileProvisionInfo {
        let buildType: String
        if dict.isEmpty {
            buildType = BuildType.developerId
        } else if (dict["ProvisionsAllDevices"] as? Bool) == true {
            buildType = BuildType.enterprise
        } else if let devices = dict["ProvisionedDevices"] as? [String], !devices.isEmpty {
            let entitlements = dict["Entitlements"] as? [String: Any]
            let getTaskAllow = (entitlements?["get-task-allow"] as? Bool) == true
            buildType = getTaskAllow ? BuildType.development : BuildType.adHoc
        } else {
            buildType = BuildType.appStore
        }

        return MobileProvisionInfo(
            isValid: true,
            uuid: dict["UUID"] as? String,
            teamId: (dict["TeamIdentifier"] as? [String])?.first,
            teamName: dict["TeamName"] as? String,
            buildType: buildType,
            createDate: dict["CreationDate"] as? Date,
            expirationDate: dict["ExpirationDate"] as? Date,
            provisionedDevices: dict["ProvisionedDevices"] as? [String]
        )
    }
}

public final class ABMobileProvisionInfo: NSObject {
    public let isValid: Bool
    public let uuid: String?
    public let teamId: String?
    public let teamName: String?
    public let buildType: String?
    public let createDate: Date?
    public let expirationDate: Date?
    public let provisionedDevices: [String]?

    init(_ info: MobileProvisionInfo) {
        isValid = info.isValid
        uuid = info.uuid
        teamId = info.teamId
        teamName = info.teamName
        buildType = info.buildType
        createDate = info.createDate
        expirationDate = info.expirationDate
        provisionedDevices = info.provisionedDevices
    }
}

public final class ABMobileProvisionParser: NSObject {
    public static func parseFile(atPath path: String) -> ABMobileProvisionInfo {
        ABMobileProvisionInfo(MobileProvisionParser.parse(contentsOf: URL(fileURLWithPath: path),
                                                          fileSystem: FileManagerFileSystem()))
    }
}
