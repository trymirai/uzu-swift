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
            url: "https://artifacts.trymirai.com/uzu-swift/releases/0.1.7.zip",
            checksum: "0bd8f4591e2132fead67bd532b55b57f4c3733a4cabd06e9bbe7774a480c06e7"
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
