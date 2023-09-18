//
//  DefaultArchiveManager.swift
//
//
//  Created by Vineet Choudhary on 16/09/23.
//

import Foundation
import ZIPFoundation

final class DefaultArchiveManager: ArchiveManager {
	let fileManager: FileManager

	init(fileManager: FileManager) {
		self.fileManager = fileManager
	}

	func unzip(file: URL) async throws -> ArchiveFiles {
		let temporaryDirectory = fileManager.temporaryDirectory.appending(path: UUID().uuidString)
		guard let archive = Archive(url: file, accessMode: .read) else {
			throw AppBoxError.archiveError(.unableToReadFile)
		}

		// get app bundle path
		let appEntry = archive.makeIterator()
			.first { entry in
				let path = entry.path.lowercased()
				return path.hasPrefix("payload/") && path.hasSuffix(".app/")
			}

		guard let appEntry else {
			throw AppBoxError.archiveError(.unableToFindAppBundle)
		}

		// extract Info.plist
		let infoPlist = try await extract(.infoPlist, root: appEntry, in: archive, to: temporaryDirectory)

		// extract embedded.mobileprovision if available
		do {
			let mobileProvision = try await extract(.mobileProvision, root: appEntry, in: archive, to: temporaryDirectory)
			return .init(infoPlist: infoPlist, mobileProvision: mobileProvision)
		} catch {
			Log.notice("Provisioning profile not found in IPA. Error - \(error)")
		}

		return .init(infoPlist: infoPlist, mobileProvision: nil)
	}

	private func extract(_ bundleFile: BundleFile, root: Entry, in archive: Archive, to: URL) async throws -> URL {
		guard let entry = archive[bundleFile.path(rootPath: root.path)] else {
			switch bundleFile {
			case .infoPlist:
				throw AppBoxError.archiveError(.unableToFindInfoPlist)
			case .mobileProvision:
				throw AppBoxError.archiveError(.unableToFindMobileProvision)
			}
		}

		let destinationPath = to.appending(path: bundleFile.rawValue)
		let crc = try archive.extract(entry, to: destinationPath)
		Log.debug("CRC for \(bundleFile.rawValue): \(crc)")
		return destinationPath
	}
}
