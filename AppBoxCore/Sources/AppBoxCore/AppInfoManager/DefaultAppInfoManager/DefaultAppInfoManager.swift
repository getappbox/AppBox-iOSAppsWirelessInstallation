//
//  DefaultAppInfoManager.swift
//
//
//  Created by Vineet Choudhary on 16/09/23.
//

import Foundation

final class DefaultAppInfoManager: AppInfoManager {
	private let archiveFiles: ArchiveFiles

	init(archiveFiles: ArchiveFiles) {
		self.archiveFiles = archiveFiles
	}

	func manifestFile(ipa: URL) -> URL {
		ipa
	}

	func appInfoFile(mainfest: URL) -> URL {
		mainfest
	}
}
