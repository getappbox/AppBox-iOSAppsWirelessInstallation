//
//  MobileProvision.swift
//  
//
//  Created by Vineet Choudhary on 18/09/23.
//

import Foundation

struct MobileProvision: Codable {
	let uuid: String
	let teamName: String
	let isEnterprise: Bool = false
	let expirationDate: Date
	let creationDate: Date

	enum CodingKeys: String, CodingKey {
		case uuid = "UUID"
		case teamName = "TeamName"
		case isEnterprise = "ProvisionsAllDevices"
		case expirationDate = "ExpirationDate"
		case creationDate = "CreationDate"
	}
}

extension MobileProvision {
	static func data(from file: URL?) throws -> Data? {
		guard let file else {
			return nil
		}

		do {
			let binaryString = try String(contentsOf: file, encoding: .isoLatin1)
			let scanner = Scanner(string: binaryString)
			_ = scanner.scanUpToString("<plist")
			guard let plist = scanner.scanUpToString("</plist>") else {
				return nil
			}

			let mobileProvisionPlist = plist.appending("</plist>")
			return mobileProvisionPlist.data(using: .utf8)
		} catch {
			Log.notice("Unable to get embedded.mobileprovision data. Error - \(error)")
			return nil
		}
	}
}
