//
//  LaunchArguments.swift
//  AppBoxCore
//
//  Created by Vineet Choudhary on 19/01/23.
//

import Foundation

public struct AppBoxCore {
	private let fileManager = FileManager.default
	private let archiveManager: ArchiveManager

	private let launchArguments: LaunchArguments

	public init(launchArguments: LaunchArguments) {
		self.launchArguments = launchArguments

		// static initializer
		Log.initialize()

		// dependency initializer
		self.archiveManager = DefaultArchiveManager(fileManager: fileManager)

		Log.debug(launchArguments.description)
    }

	public func upload() async throws {
		let archiveFiles = try await archiveManager.unzip(file: launchArguments.ipaURL)
		Log.debug(archiveFiles.description)
	}
}
