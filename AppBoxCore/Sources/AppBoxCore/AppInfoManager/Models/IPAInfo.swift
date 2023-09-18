//
//  IPAInfo.swift
//
//
//  Created by Vineet Choudhary on 18/09/23.
//

import Foundation

struct IPAInfo {
	private let archiveFiles: ArchiveFiles

	let infoPlist: InfoPlist
	let mobileProvision: MobileProvision?

	init(archiveFiles: ArchiveFiles) throws {
		self.archiveFiles = archiveFiles

		let decoder = PropertyListDecoder()

		// decode Info.plist file to `InfoPlist`
		let infoPlistData = try InfoPlist.data(from: archiveFiles.infoPlist)
		self.infoPlist = try decoder.decode(InfoPlist.self, from: infoPlistData)

		// decode embedded.mobileprovision file to `MobileProvision`
		if let data = try MobileProvision.data(from: archiveFiles.mobileProvision) {
			self.mobileProvision = try decoder.decode(MobileProvision.self, from: data)
		} else {
			self.mobileProvision = nil
		}
	}
}
