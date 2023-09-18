//
//  UploadFiles.swift
//
//
//  Created by Vineet Choudhary on 18/09/23.
//

import Foundation

// = "appinfo.json"
// = "manifest.plist"

enum UploadFiles: String {
	case appInfo
	case manifest
	case ipa

	func filePath(localURL: URL) -> String {
		localURL.absoluteString
	}
}
