// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OikomiKit",
    defaultLocalization: "ja",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        .macOS(.v26),
    ],
    products: [
        .library(name: "OikomiKit", targets: ["OikomiKit"]),
    ],
    targets: [
        .target(
            name: "OikomiKit",
            path: "Sources/OikomiKit"
        ),
        .testTarget(
            name: "OikomiKitTests",
            dependencies: ["OikomiKit"],
            path: "Tests/OikomiKitTests"
        ),
    ]
)
