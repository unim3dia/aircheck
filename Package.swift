// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "AircheckCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "AircheckCore", targets: ["AircheckCore"])],
    targets: [
        .target(name: "AircheckCore"),
        .testTarget(
            name: "AircheckCoreTests",
            dependencies: ["AircheckCore"]
        )
    ],
    swiftLanguageModes: [.v6]
)
