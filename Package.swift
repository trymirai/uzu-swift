// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Uzu",
    platforms: [
        .iOS("17.0"),
        .macOS("15.0"),
    ],
    products: [
        .library(name: "Uzu", targets: ["Uzu"]),
        .executable(name: "example", targets: ["Example"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.1")
    ],
    targets: [
        .binaryTarget(
            name: "uzu",
            url: "https://artifacts.trymirai.com/uzu-swift/releases/0.1.15.zip",
            checksum: "e5965a7cd234b09a051a06c37b1b5590dc8098133fe1d7cbd5d00f1cb4810bef"
        ),
        .target(
            name: "Uzu",
            dependencies: ["uzu"],
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedFramework("SystemConfiguration"),
                .linkedFramework("Metal"),
                .linkedFramework("MetalPerformanceShadersGraph"),
            ]
        ),
        .executableTarget(
            name: "Example",
            dependencies: [
                "Uzu",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/Example"
        ),
        .testTarget(
            name: "UzuTests",
            dependencies: ["Uzu"]
        ),
    ]
)
