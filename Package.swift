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
            url: "https://artifacts.trymirai.com/uzu-swift/releases/0.1.0.zip",
            checksum: "930125d8b9f38b6963ced1f46c84a78089c115fb5cfe8297d9c1a54342518eaf"
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
