//
//  BuildUploadService.swift
//  AppBoxCore
//

import Foundation

/// Everything one build upload needs, independent of who is driving it.
public struct BuildUploadRequest {
    public var ipaURL: URL
    public var settings: UploadSettings
    public var share: BuildShareOptions
    public var keepSameLink: Bool
    /// Custom storage folder; defaults to the app's bundle identifier.
    public var bundleDirectory: String?
    /// Identifies this build's folder; pass a fresh value per upload.
    public var uuid: String

    public init(ipaURL: URL, settings: UploadSettings = UploadSettings(),
                share: BuildShareOptions = BuildShareOptions(), keepSameLink: Bool = false,
                bundleDirectory: String? = nil, uuid: String = UUID().uuidString) {
        self.ipaURL = ipaURL
        self.settings = settings
        self.share = share
        self.keepSameLink = keepSameLink
        self.bundleDirectory = bundleDirectory
        self.uuid = uuid
    }
}

/// What a completed upload produced.
public struct BuildUploadOutcome {
    public let uuid: String
    public let metadata: BuildMetadata
    public let paths: BuildRemotePaths
    public let provisioning: MobileProvisionInfo?
    public let ipaFileSizeMB: Int
    public let result: UploadResult
}

/// Failures a build upload can end in; `exitCode` matches the codes the CLI has always returned.
public enum BuildUploadError: Error {
    case ipaNotFound(URL)
    case invalidInfoPlist
    case extractionFailed(Error)
    case manifestCreationFailed(Error)
    case uploadFailed(Error)

    public var exitCode: Int32 {
        switch self {
        case .manifestCreationFailed: return 118
        case .ipaNotFound: return 119
        case .invalidInfoPlist: return 120
        case .extractionFailed: return 121
        case .uploadFailed: return 124
        }
    }

    public var message: String {
        switch self {
        case .ipaNotFound(let url): return "AppBox was not able to find IPA file at \(url.path)."
        case .invalidInfoPlist: return "AppBox was not able to find Info.plist in your IPA."
        case .extractionFailed(let error): return error.localizedDescription
        case .manifestCreationFailed(let error): return error.localizedDescription
        case .uploadFailed(let error): return error.localizedDescription
        }
    }
}

/// Runs a build from a local IPA to a shareable install link: extract, read metadata, upload, and publish the manifest and install page.
public final class BuildUploadService {

    private let provider: StorageProvider
    private let progress: ProgressReporter
    private let shortLinkService: ShortLinkService?
    private let reachability: Reachability?
    private let archiveExtractor: ArchiveExtractor
    private let fileSystem: FileSystem
    private let dateProvider: DateProvider

    public init(provider: StorageProvider,
                progress: ProgressReporter = NullProgressReporter(),
                shortLinkService: ShortLinkService? = nil,
                reachability: Reachability? = nil,
                archiveExtractor: ArchiveExtractor = ZipFoundationArchiveExtractor(),
                fileSystem: FileSystem = FileManagerFileSystem(),
                dateProvider: DateProvider = SystemDateProvider()) {
        self.provider = provider
        self.progress = progress
        self.shortLinkService = shortLinkService
        self.reachability = reachability
        self.archiveExtractor = archiveExtractor
        self.fileSystem = fileSystem
        self.dateProvider = dateProvider
    }

    public func run(_ request: BuildUploadRequest) async throws -> BuildUploadOutcome {
        let ipaURL = URL(fileURLWithPath: request.ipaURL.path)
        guard fileSystem.fileExists(at: ipaURL) else {
            throw BuildUploadError.ipaNotFound(ipaURL)
        }

        let workingDirectory = try makeWorkingDirectory()
        defer { try? FileManager.default.removeItem(at: workingDirectory) }

        progress.report(stage: .extracting, message: "Extracting files...", fractionCompleted: nil)
        let extracted: ExtractedIPA
        do {
            extracted = try IPAExtractor(archiveExtractor: archiveExtractor)
                .extract(ipaAt: ipaURL, to: workingDirectory)
        } catch {
            throw BuildUploadError.extractionFailed(error)
        }

        guard let metadata = BuildMetadata.read(fromInfoPlistAt: extracted.infoPlistURL) else {
            throw BuildUploadError.invalidInfoPlist
        }

        let provisioning = extracted.mobileProvisionURL.map {
            MobileProvisionParser.parse(contentsOf: $0, fileSystem: fileSystem)
        }
        let paths = BuildRemotePaths(metadata: metadata, uuid: request.uuid,
                                     bundleDirectory: request.bundleDirectory,
                                     keepSameLink: request.keepSameLink)
        let sizeMB = ipaFileSizeMB(at: ipaURL)

        let entry = AppVersionInput(
            name: metadata.name, version: metadata.version, build: metadata.build,
            identifier: metadata.identifier, manifestLink: "", timestamp: 0, shareableIPALink: "",
            includeIPALink: request.settings.includeIPALink,
            includeDetails: request.settings.includeDetails,
            minOSVersion: metadata.minimumOSVersion, supportedDevice: metadata.supportedDevice,
            buildType: provisioning?.buildType, ipaFileSizeMB: sizeMB,
            provisioningCreateDate: provisioning?.createDate,
            provisioningExpirationDate: provisioning?.expirationDate,
            teamId: provisioning?.teamId, teamName: provisioning?.teamName,
            provisioningUUID: provisioning?.uuid, provisionedDevices: provisioning?.provisionedDevices)

        let plan = UploadPlan(
            ipaLocalURL: ipaURL, workingDirectory: workingDirectory,
            ipaRemotePath: paths.ipa, manifestRemotePath: paths.manifest, appInfoRemotePath: paths.appInfo,
            name: metadata.name, version: metadata.version, build: metadata.build,
            identifier: metadata.identifier, entryInput: entry,
            keepSameLink: request.keepSameLink,
            keepPreviousVersions: request.settings.keepPreviousVersions)

        let coordinator = UploadCoordinator(provider: provider, progress: progress,
                                            dateProvider: dateProvider,
                                            shortLinkService: shortLinkService, reachability: reachability)
        do {
            let result = try await coordinator.run(plan)
            return BuildUploadOutcome(uuid: request.uuid, metadata: metadata, paths: paths,
                                      provisioning: provisioning, ipaFileSizeMB: sizeMB, result: result)
        } catch let error as UploadCoordinatorError {
            if case .manifestCreationFailed(let underlying) = error {
                throw BuildUploadError.manifestCreationFailed(underlying)
            }
            throw BuildUploadError.uploadFailed(error)
        } catch {
            throw BuildUploadError.uploadFailed(error)
        }
    }

    private func makeWorkingDirectory() throws -> URL {
        try ABStorePaths.makeTemporaryWorkingDirectory(prefix: "upload-")
    }

    private func ipaFileSizeMB(at url: URL) -> Int {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = (attributes[.size] as? NSNumber)?.int64Value else {
            return 0
        }
        return Int(size / 1_000_000)
    }
}
