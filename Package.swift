// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Uzu",
    platforms: [
        .iOS("17.0"),
        .macOS("14.0"),
    ],
    products: [
        .library(name: "Uzu", targets: ["Uzu"])
        .executableTarget(
        name: "Example",
        dependencies: [
            "Uzu",
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
            .executable(name: "example", targets: ["Example"]),
        ],
        path: "Sources/Example"
    ) ,
    ],
    targets: [
        .binaryTarget(
            name: "uzu",
            url: "https://artifacts.trymirai.com/uzu-swift/releases/0.1.9.zip",
            checksum: "9df75e720957ffe945a4b7b2db1717f10b91db53b0a9f99325c6352b851dc746"
        ),
        .target(
            name: "Uzu",
            dependencies: ["uzu"],
            path: "Sources/Uzu",
            linkerSettings: [
                .linkedLibrary("c++"),
                .linkedFramework("SystemConfiguration"),
            ]
        ),
        .testTarget(
            name: "UzuTests",
            dependencies: ["Uzu"],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        ),
    ]
)
