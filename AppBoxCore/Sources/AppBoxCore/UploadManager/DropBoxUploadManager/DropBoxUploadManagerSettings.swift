//
//  DropBoxUploadManagerSettings.swift
//
//
//  Created by Vineet Choudhary on 16/09/23.
//

import Foundation

struct DropBoxUploadManagerSettings: UploadManagerSettings {
	let appKey: String
	let accessToken: String

	init(appKey: String, accessToken: String) {
		self.appKey = appKey
		self.accessToken = accessToken
	}
}
