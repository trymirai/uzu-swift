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
            checksum: "23ac555348cc1092945c856636ea0656749735d12c9bb9771f2904e4553be49c"
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
