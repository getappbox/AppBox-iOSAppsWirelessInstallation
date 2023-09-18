//
//  ArchiveFiles.swift
//
//
//  Created by Vineet Choudhary on 16/09/23.
//

import Foundation

struct ArchiveFiles {
	let infoPlist: URL
	let mobileProvision: URL?
}

extension ArchiveFiles: CustomStringConvertible {
	var description: String {
		"Archive files:\n" +
		"\tInfo.plist = \(infoPlist.absoluteString)\n" +
		"\tembedded.mobileprovision = \(mobileProvision?.absoluteString ?? "-")"
	}
}
