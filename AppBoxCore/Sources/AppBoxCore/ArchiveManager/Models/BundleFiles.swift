//
//  BundleFiles.swift
//
//
//  Created by Vineet Choudhary on 16/09/23.
//

import Foundation

enum BundleFiles: String {
	case infoPlist = "Info.plist"
	case mobileProvision = "embedded.mobileprovision"

	func path(rootPath: String) -> String {
		rootPath.appending(self.rawValue)
	}
}
