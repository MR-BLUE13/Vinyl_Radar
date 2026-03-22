// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "VinylRadar",
    defaultLocalization: "zh-Hans",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "VinylRadar",
            targets: ["VinylRadar"]
        ),
    ],
    targets: [
        .target(
            name: "VinylRadar",
            resources: [
                .process("Resources"),
            ]
        ),
        .testTarget(
            name: "VinylRadarTests",
            dependencies: ["VinylRadar"]
        ),
    ]
)
