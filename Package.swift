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
            url: "https://artifacts.trymirai.com/uzu-swift/releases/0.1.8.zip",
            checksum: "ea15c20de4f51d73c6d39f40a724c7190ecfd90c9c29abc585c295211c120ccc"
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
