//
//  UploadManager.swift
//  AppBox

import AppKit
import os
import AppBoxCore

public final class UploadManager: NSObject {

    private static let log = Logger(subsystem: "com.developerinsider.AppBox", category: "UploadManager")

    public var ipaUploadInfo: IPAUploadInfo?
    public weak var currentViewController: NSViewController?
    public weak var uploadRecord: ABUploadRecord?
    public var lastfailedOperation: BlockOperation?

    public var errorBlock: ((Error?, Bool) -> Void)?
    public var completionBlock: (() -> Void)?

    private var workingDirectory: String?

    // MARK: - Setup

    public static func setupDBClientsManager() {
        DropboxSession.setup(appKey: AppServices.appKeyProvider.cachedKey())
    }

    deinit {
        cleanupWorkingDirectory()
    }

    private func cleanupWorkingDirectory() {
		guard let workingDirectory, FileManager.default.fileExists(atPath: workingDirectory) else {
			return
		}

		do {
			try FileManager.default.removeItem(atPath: workingDirectory)
		} catch {
			Self.log.warning("Failed to clean temp directory: \(error.localizedDescription)")
		}
    }

    private func createNewWorkingDirectory() {
        do {
            workingDirectory = try ABStorePaths.makeTemporaryWorkingDirectory(prefix: "delete-").path
        } catch {
            Self.log.info("Unable to create temporary working directory: \(error.localizedDescription)")
        }
    }

    // MARK: - Upload

    public func uploadIPAFile(_ ipaFileURL: URL) {
        let ipaPath = (ipaFileURL as NSURL).resourceSpecifier?.removingPercentEncoding ?? ipaFileURL.path
        let localURL = URL(fileURLWithPath: ipaPath)
        guard let info = ipaUploadInfo else { return }
        info.ipaFullPath = localURL

        if !AppDelegate.appDelegate.isInternetConnected {
            showStatus("Waiting for the Internet Connection.", showProgressBar: true, withProgress: -1)
        }
        uploadIPAFileWithoutUnzip(localURL)
    }

    public func uploadIPAFileWithoutUnzip(_ ipaURL: URL) {
        if AppDelegate.appDelegate.isInternetConnected {
            runUpload(withIPAURL: ipaURL)
        } else {
            lastfailedOperation = BlockOperation { [weak self] in
                self?.runUpload(withIPAURL: ipaURL)
            }
        }
    }

    private func runUpload(withIPAURL ipaURL: URL) {
        guard let info = ipaUploadInfo else { return }

        let settings = UploadSettings(
            chunkSizeMB: UserData.uploadChunkSize(),
            includeIPALink: UserData.downloadIPAEnable(),
            includeDetails: UserData.moreDetailsEnable(),
            keepPreviousVersions: UserData.showPreviousVersions())
        let request = BuildUploadRequest(
            ipaURL: ipaURL,
            settings: settings,
            keepSameLink: info.isKeepSameLinkEnabled,
            bundleDirectory: info.bundleDirectory?.absoluteString,
            uuid: info.uuid ?? Common.generateUUID())

        let reachability = ClosureReachability { AppDelegate.appDelegate.isInternetConnected }
        let provider = DropboxSession.makeProvider(chunkSizeBytes: settings.chunkSizeBytes,
                                                   reachability: reachability)
        let reporter = ClosureProgressReporter { [weak self] message, fraction in
            DispatchQueue.main.async { self?.reportUploadProgress(message: message, fraction: fraction) }
        }
        let shortLink = ClosureShortLinkService { [weak self] request in
            await self?.shortenLink(for: request) ?? nil
        }

        let service = BuildUploadService(provider: provider, progress: reporter,
                                         shortLinkService: shortLink, reachability: reachability)
        Task { [weak self] in
            do {
                let outcome = try await service.run(request)
                DispatchQueue.main.async { self?.handleUploadSuccess(outcome) }
            } catch {
                DispatchQueue.main.async { self?.handleUploadFailure(error) }
            }
        }
    }

    private func reportUploadProgress(message: String?, fraction: Double) {
        var status = (message?.isEmpty == false) ? message! : "Finalising…"
        if fraction >= 0 {
            status += " (\(Int(fraction * 100))%)"
        }
        showStatus(status, showProgressBar: true, withProgress: fraction < 0 ? -1 : fraction)
    }

    /// Stash the long (unique) link, then ask the AppBox backend to shorten it — nil falls back to the long URL (the coordinator's existing behavior).
    private func shortenLink(for request: ShortLinkRequest) async -> URL? {
        await MainActor.run { [weak self] in
            self?.ipaUploadInfo?.uniquelinkShareableURL = request.longURL
        }
        return await AppServices.serviceClient.shortLink(for: request)
    }

    /// Copies the pipeline's metadata, paths and links back onto the model the sheets and dashboard read.
    private func handleUploadSuccess(_ outcome: BuildUploadOutcome) {
        if let info = ipaUploadInfo {
            info.uuid = outcome.uuid
            info.name = outcome.metadata.name
            info.version = outcome.metadata.version
            info.build = outcome.metadata.build
            info.identifer = outcome.metadata.identifier
            info.miniOSVersion = outcome.metadata.minimumOSVersion
            info.supportedDevice = outcome.metadata.supportedDevice
            info.ipaFileSize = NSNumber(value: outcome.ipaFileSizeMB)
            if let provisioning = outcome.provisioning {
                info.buildType = provisioning.buildType
                info.mobileProvision = MobileProvision(provisioning)
            }

            info.bundleDirectory = URL(string: outcome.paths.bundleDirectory)
            info.dbDirectory = URL(string: outcome.paths.buildDirectory)
            info.dbIPAFullPath = URL(string: "/" + outcome.paths.ipa.components.joined(separator: "/"))
            info.dbManifestFullPath = URL(string: "/" + outcome.paths.manifest.components.joined(separator: "/"))
            info.dbAppInfoJSONFullPath = URL(string: "/" + outcome.paths.appInfo.components.joined(separator: "/"))

            info.ipaFileDBShareableURL = outcome.result.ipaLink
            info.manifestFileSharableURL = outcome.result.manifestLink
            info.uniquelinkShareableURL = outcome.result.appInfoSharedLink
            info.appShortShareableURL = outcome.result.shortLink
            info.appLongShareableURL = outcome.result.installLink
        }
        completionBlock?()
    }

    private func handleUploadFailure(_ error: Error) {
        if let uploadError = error as? BuildUploadError {
            switch uploadError {
            case .ipaNotFound, .invalidInfoPlist, .extractionFailed:
                _ = Common.showAlert(withTitle: "AppBox - Error", andMessage: uploadError.message)
                errorBlock?(nil, true)
                return
            case .manifestCreationFailed(let underlying), .uploadFailed(let underlying):
                DBErrorHandler.handleStorageError(underlying, fallbackMessage: nil)
                errorBlock?(underlying, true)
                return
            }
        }
        DBErrorHandler.handleStorageError(error, fallbackMessage: nil)
        errorBlock?(error, true)
    }

    // MARK: - Delete

    public func deleteBuildFromDropboxAndDashboard() {
        let keepSameLink = ipaUploadInfo?.isKeepSameLinkEnabled ?? false
        let appInfoPath = ipaUploadInfo?.dbAppInfoJSONFullPath?.absoluteString ?? ""
        let appFolder = uploadRecord?.dbFolderName ?? ""
        let buildFolder = ipaUploadInfo?.dbDirectory?.absoluteString ?? ""
        let requiredPaths = keepSameLink ? [appInfoPath, appFolder] : [buildFolder]
        guard requiredPaths.allSatisfy({ !$0.isEmpty }) else {
            _ = Common.showAlert(
                withTitle: "Can't delete from Dropbox",
                andMessage: "This build is missing its Dropbox location, so AppBox doesn't know what to remove.\n\nUse \"Delete only from Dashboard\" to remove the record.")
            errorBlock?(nil, true)
            return
        }

        createNewWorkingDirectory()
        showStatus("Deleting...", showProgressBar: true, withProgress: -1)

        let plan = DeletePlan(
            keepSameLink: keepSameLink,
            appInfoRemotePath: RemotePath(path: appInfoPath),
            manifestLinkToRemove: uploadRecord?.dbSharedManifestURL ?? "",
            appFolderPath: RemotePath(path: appFolder),
            buildFolderPath: RemotePath(path: buildFolder),
            workingDirectory: URL(fileURLWithPath: workingDirectory ?? ""))

        let chunkSizeBytes = UserData.uploadChunkSize() * (1024 * 1024)
        let reachability = ClosureReachability { AppDelegate.appDelegate.isInternetConnected }
        let provider = DropboxSession.makeProvider(chunkSizeBytes: chunkSizeBytes, reachability: reachability)
        let reporter = ClosureProgressReporter { [weak self] message, _ in
            DispatchQueue.main.async {
                self?.showStatus(message ?? "Deleting...", showProgressBar: true, withProgress: -1)
            }
        }

        let coordinator = DeleteCoordinator(provider: provider, progress: reporter, reachability: reachability)
        Task { [weak self] in
            do {
                _ = try await coordinator.run(plan)
                DispatchQueue.main.async { self?.handleDeleteSuccess() }
            } catch {
                DispatchQueue.main.async { self?.handleDeleteFailure(error) }
            }
        }
    }

    private func handleDeleteSuccess() {
		if let view = currentViewController?.view {
			ABHudViewController.hideAllHud(fromView: view, after: 0)
		}

        completionBlock?()
    }

    private func handleDeleteFailure(_ error: Error) {
		if let view = currentViewController?.view {
			ABHudViewController.hideAllHud(fromView: view, after: 0)
		}

        DBErrorHandler.handleStorageError(error, fallbackMessage: "Unable to delete build.")
    }

    public func deleteBuildFromDashboard() {
        showStatus("Deleting...", showProgressBar: true, withProgress: -1)
        completionBlock?()
    }

    // MARK: - Status / HUD

    private func showStatus(_ status: String, showProgressBar: Bool, withProgress progress: Double) {
        Self.log.debug("\(status)")
		guard let view = currentViewController?.view else {
			return
		}

        if progress == -1 {
			if showProgressBar {
				ABHudViewController.showStatus(status, onView: view)
			} else {
				ABHudViewController.showOnlyStatus(status, onView: view)
			}
        } else {
			if showProgressBar {
				ABHudViewController.showStatus(status, witProgress: progress, onView: view)
			} else {
				ABHudViewController.showOnlyStatus(status, onView: view)
			}
        }
    }
}

extension UploadManager: @unchecked Sendable {}

// MARK: - Core protocol adapters (closure-backed)

private final class ClosureReachability: Reachability {
    private let block: () -> Bool

	init(_ block: @escaping () -> Bool) {
		self.block = block
	}

	var isConnected: Bool {
		block()
	}
}

private final class ClosureProgressReporter: ProgressReporter {
    private let block: (String?, Double) -> Void

	init(_ block: @escaping (String?, Double) -> Void) {
		self.block = block
	}

    func report(stage: UploadStage, message: String?, fractionCompleted: Double?) {
        block(message, fractionCompleted ?? -1)
    }
}

private final class ClosureShortLinkService: ShortLinkService {
    private let block: (ShortLinkRequest) async -> URL?

	init(_ block: @escaping (ShortLinkRequest) async -> URL?) {
		self.block = block
	}

	func shortLink(for request: ShortLinkRequest) async -> URL? {
		await block(request)
	}
}
