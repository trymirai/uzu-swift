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
            url: "https://artifacts.trymirai.com/sdk-ios/releases/0.1.0.zip",
            checksum: "be5afd925e3f6ade8076e89e3965cb409f557ae32f580555332caf40c0fc1a14"
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
    ]
)
