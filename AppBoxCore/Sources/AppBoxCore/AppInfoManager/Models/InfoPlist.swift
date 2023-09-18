//
//  InfoPlist.swift
//
//
//  Created by Vineet Choudhary on 18/09/23.
//

import Foundation

struct InfoPlist: Codable {
	enum DeviceFamily: Int, Codable {
		case iPhone = 1
		case iPad = 2
	}

	let version: String
	let build: String
	let bundleIdentifier: String
	let executableName: String
	let bundleName: String
	let supportedDevices: [DeviceFamily]

	enum CodingKeys: String, CodingKey {
		case version = "CFBundleShortVersionString"
		case build = "CFBundleVersion"
		case bundleIdentifier = "CFBundleIdentifier"
		case executableName = "CFBundleExecutable"
		case bundleName = "CFBundleName"
		case supportedDevices = "UIDeviceFamily"
	}
}

extension InfoPlist {
	static func data(from file: URL) throws -> Data {
		try Data(contentsOf: file)
	}
}
