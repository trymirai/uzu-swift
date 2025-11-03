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
            url: "https://artifacts.trymirai.com/uzu-swift/releases/0.1.40.zip",
            checksum: "0635ebae4c842dd2ce3147bd1c0a674173fcf91b66307d128b78c9a7e8dd7852"
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
