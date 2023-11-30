// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "SmallWorld",
    platforms: [
        .iOS(.v13),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SmallWorld",
            targets: ["SmallWorld"]
        ),
        .library(
            name: "SmallWorldDatabase",
            targets: ["SmallWorldDatabase"]
        ),
        .library(
            name: "SmallWorldExtras",
            targets: ["SmallWorldExtras"]
        ),
        .executable(
            name: "SmallWorldVisualizer",
            targets: ["SmallWorldVisualizer"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/jadengeller/core-lmdb.git", branch: "main"),
        .package(url: "https://github.com/JadenGeller/swift-priority-heap", branch: "release/0.4.3"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SmallWorld",
            dependencies: [
                .product(name: "CoreLMDB", package: "core-lmdb"),
                .product(name: "PriorityHeapModule", package: "swift-priority-heap"),
                .product(name: "PriorityHeapAlgorithms", package: "swift-priority-heap"),
                .product(name: "RealModule", package: "swift-numerics"),
            ]
        ),
        .target(
            name: "SmallWorldDatabase",
            dependencies: [
                "SmallWorld",
                .product(name: "CoreLMDB", package: "core-lmdb"),
                .product(name: "CoreLMDBCoders", package: "core-lmdb")
            ]
        ),
        .target(
            name: "SmallWorldExtras",
            dependencies: ["SmallWorld"]
        ),
        .executableTarget(
            name: "SmallWorldVisualizer",
            dependencies: ["SmallWorld", "SmallWorldExtras"]
        ),
        .testTarget(
            name: "SmallWorldTests",
            dependencies: ["SmallWorld", "SmallWorldExtras"]
        ),
    ]
)
