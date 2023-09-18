//
//  DefaultAppInfoManager.swift
//
//
//  Created by Vineet Choudhary on 16/09/23.
//

import Foundation

final class DefaultAppInfoManager: AppInfoManager {
	private let archiveFiles: ArchiveFiles
	private let ipaInfo: IPAInfo

	init(archiveFiles: ArchiveFiles) throws {
		self.archiveFiles = archiveFiles
		self.ipaInfo = try IPAInfo(archiveFiles: archiveFiles)
	}

	func manifestFile(ipa: URL) -> URL {
		ipa
	}

	func appInfoFile(mainfest: URL) -> URL {
		mainfest
	}
}
