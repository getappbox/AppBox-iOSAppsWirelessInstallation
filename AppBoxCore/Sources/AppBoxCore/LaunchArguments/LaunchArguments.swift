//
//  LaunchArguments.swift
//  AppBoxCore
//
//  Created by Vineet Choudhary on 19/01/23.
//

import Foundation

public struct LaunchArguments {
	let ipaPath: String
	let emails: String?
	let customMessage: String?
	let directoryName: String?
	let keepSameLink: Bool

	var ipaURL: URL {
		URL(filePath: ipaPath)
	}

	public init(ipaPath: String, emails: String?, customMessage: String?, directoryName: String?, keepSameLink: Bool) {
		self.ipaPath = ipaPath
		self.emails = emails
		self.customMessage = customMessage
		self.directoryName = directoryName
		self.keepSameLink = keepSameLink
	}
}

extension LaunchArguments: CustomStringConvertible {
	public var description: String {
		"Launch Arguments:\n" +
		"\tIPA path = \(ipaPath)\n" +
		"\tEmails = \(String(describing: emails))\n" +
		"\tCustom Message = \(String(describing: customMessage))\n" +
		"\tDirectory Name = \(String(describing: directoryName))\n" +
		"\tKeep same link = \(keepSameLink)"
	}
}
