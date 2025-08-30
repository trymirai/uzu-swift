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
            url: "https://artifacts.trymirai.com/uzu-swift/releases/0.1.6.zip",
            checksum: "191fc9d3e917c39948eeab9b52b4aea1afcbb06657adb635b69bc22c7b07cfea"
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
