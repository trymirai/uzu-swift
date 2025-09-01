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
            url: "https://artifacts.trymirai.com/uzu-swift/releases/0.1.11.zip",
            checksum: "b0b55e948d87b9cc23c295b09ecfd709a241122d723cd41543985ff3e89f904f"
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
