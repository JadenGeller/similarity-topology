// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "swift-hnsw",
    platforms: [
        .iOS(.v13),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "HNSW",
            targets: ["HNSW"]
        ),
        .library(
            name: "HNSWExtras",
            targets: ["HNSWExtras"]
        ),
        .executable(
            name: "HNSWVisualizer",
            targets: ["HNSWVisualizer"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/JadenGeller/swift-priority-heap", branch: "release/0.4.3"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "HNSW",
            dependencies: [
                .product(name: "PriorityHeapModule", package: "swift-priority-heap"),
                .product(name: "PriorityHeapAlgorithms", package: "swift-priority-heap"),
                .product(name: "RealModule", package: "swift-numerics"),
            ]
        ),
        .target(
            name: "HNSWExtras",
            dependencies: ["HNSW"]
        ),
        .executableTarget(
            name: "HNSWVisualizer",
            dependencies: ["HNSW", "HNSWExtras"]
        ),
        .testTarget(
            name: "HNSWTests",
            dependencies: ["HNSW", "HNSWExtras"]
        ),
    ]
)
