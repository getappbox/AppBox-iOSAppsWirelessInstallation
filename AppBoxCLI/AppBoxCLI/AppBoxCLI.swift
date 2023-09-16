//
//  main.swift
//  AppBoxCLI
//
//  Created by Vineet Choudhary on 19/01/23.
//

import Foundation
import AppBoxCore

@main
struct AppBoxCLI {
	static func main() async throws {
		let arguments = ParsableLaunchArguments.parseOrExit()

		let launchArguments: LaunchArguments = .init(
			ipaPath: arguments.ipaPath,
			emails: arguments.emails,
			customMessage: arguments.customMessage,
			directoryName: arguments.directoryName,
			keepSameLink: arguments.keepSameLink)

		let appBoxCore = AppBoxCore.init(launchArguments: launchArguments)
		try await appBoxCore.upload()
	}
}
