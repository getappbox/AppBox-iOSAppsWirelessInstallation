//
//  LaunchArguments.swift
//  AppBoxCore
//
//  Created by Vineet Choudhary on 19/01/23.
//

public struct AppBoxCore {
	private let launchArguments: LaunchArguments
	public init(launchArguments: LaunchArguments) {
		self.launchArguments = launchArguments
    }

	public func upload() {
		print("Uploading \(launchArguments.ipaPath)")
	}
}
