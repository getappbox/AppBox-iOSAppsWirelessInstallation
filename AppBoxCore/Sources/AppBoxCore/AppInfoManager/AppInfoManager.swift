//
//  AppInfoManager.swift
//
//
//  Created by Vineet Choudhary on 16/09/23.
//

import Foundation

protocol AppInfoManager {
	init(archiveFiles: ArchiveFiles)

	func manifestFile(ipa: URL) -> URL

	func appInfoFile(mainfest: URL) -> URL
}
