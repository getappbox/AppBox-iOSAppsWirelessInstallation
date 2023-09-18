// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "AppBoxCore",
	platforms: [
		.macOS(.v13), .iOS(.v16)
	],
	products: [
		.library(
			name: "AppBoxCore",
			targets: ["AppBoxCore"])
	],
	dependencies: [
		.package(url: "https://github.com/dropbox/SwiftyDropbox.git", from: "10.0.0-beta.3"),
		.package(url: "https://github.com/apple/swift-log.git", from: "1.0.0"),
		.package(url: "https://github.com/weichsel/ZIPFoundation.git", branch: "development")
	],
	targets: [
		.target(
			name: "AppBoxCore",
			dependencies: [
				.byName(name: "SwiftyDropbox"),
				.product(name: "Logging", package: "swift-log"),
				.byName(name: "ZIPFoundation")
			]),
		.testTarget(
			name: "AppBoxCoreTests",
			dependencies: ["AppBoxCore"])
	]
)
