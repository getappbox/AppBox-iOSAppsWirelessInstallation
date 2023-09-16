//
//  ParsableLaunchArguments.swift
//  AppBoxCLI
//
//  Created by Vineet Choudhary on 19/01/23.
//

import ArgumentParser
import Foundation

// swiftlint: disable line_length
struct ParsableLaunchArguments: ParsableArguments {
	@Option(help: "IPA file path in local file system")
	var ipaPath: String

	@Option(help: "Comma-separated list of email address that should receive application installation link.")
	var emails: String?

	@Option(help: "Attach personal message in the email. Supported Keywords: The {PROJECT_NAME} - For Project Name, {BUILD_VERSION} - For Build Version, and {BUILD_NUMBER} - For Build Number")
	var customMessage: String?

	@Option(help: "You can change the link by providing a Custom Dropbox Folder Name. By default folder name will be the application bundle identifier. So, AppBox will keep the same link for the IPA file available in the same folder. ")
	var directoryName: String?

	@Flag(help: "This feature will keep same short URL for all future build/IPA uploaded with same bundle identifier. If this option is enabled, you can also download the previous build with the same URL.")
	var keepSameLink = false
}
