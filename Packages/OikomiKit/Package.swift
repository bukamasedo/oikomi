// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "OikomiKit",
    defaultLocalization: "ja",
    platforms: [
        .iOS(.v26),
        .watchOS(.v26),
        // macOS は配布対象ではないが、`swift test` をホストの macOS で実行するために必要。
        .macOS(.v26),
    ],
    products: [
        .library(name: "OikomiKit", targets: ["OikomiKit"])
    ],
    targets: [
        .target(
            name: "OikomiKit",
            path: "Sources/OikomiKit",
            resources: [
                .process("Resources/Localizable.xcstrings")
            ]
        ),
        .testTarget(
            name: "OikomiKitTests",
            dependencies: ["OikomiKit"],
            path: "Tests/OikomiKitTests"
        ),
    ]
)
