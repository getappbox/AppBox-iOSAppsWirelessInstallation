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

	public init(ipaPath: String, emails: String?, customMessage: String?, directoryName: String?, keepSameLink: Bool) {
		self.ipaPath = ipaPath
		self.emails = emails
		self.customMessage = customMessage
		self.directoryName = directoryName
		self.keepSameLink = keepSameLink
	}
}
