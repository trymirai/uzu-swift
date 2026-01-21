// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Uzu",
    platforms: [
        .iOS("26.0"),
        .macOS("26.0"),
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
            url: "https://artifacts.trymirai.com/uzu-swift/releases/0.2.10.zip",
            checksum: "1d12b987e8ad9bd8124b31a01d0bf300c4193b2b8404805a8f672f741d6deefd"
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
            dependencies: ["Uzu"],
            path: "Tests"
        ),
    ]
)
