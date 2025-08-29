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
    ],
    targets: [
        .binaryTarget(

            name: "uzu",

            url: "https://artifacts.trymirai.com/uzu-swift/releases/0.1.5.zip",

            checksum: "94bb076cd8ca0aacc892cd8be10b5c399461224a32f0f3bdfb28ea2ca6bde25d"

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
