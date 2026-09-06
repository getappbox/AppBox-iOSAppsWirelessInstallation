// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AppBoxCore",
    platforms: [
        .macOS("15.0") // macOS 15 floor (supports the latest two: macOS 15 + 26); GUI + CLI both consume it.
    ],
    products: [
        .library(name: "AppBoxCore", targets: ["AppBoxCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/dropbox/SwiftyDropbox.git", .upToNextMajor(from: "10.0.0")),
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0"))
    ],
    targets: [
        .target(
            name: "AppBoxCore",
            dependencies: [
                .product(name: "SwiftyDropbox", package: "SwiftyDropbox"),
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
            resources: [
                .process("CoreData/Resources")
            ]
        ),
        .testTarget(name: "AppBoxCoreTests", dependencies: ["AppBoxCore"])
    ]
)
