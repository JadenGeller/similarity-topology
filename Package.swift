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
            name: "HNSWDurable",
            targets: ["HNSWDurable"]
        ),
        .library(
            name: "HNSWEphemeral",
            targets: ["HNSWEphemeral"]
        ),
        .library(
            name: "HNSWSample",
            targets: ["HNSWSample"]
        ),
        .executable(
            name: "HNSWVisualizer",
            targets: ["HNSWVisualizer"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
        .package(url: "https://github.com/JadenGeller/swift-priority-heap", branch: "release/0.4.3"),
        .package(url: "https://github.com/jadengeller/core-lmdb.git", branch: "main"),
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
            name: "HNSWDurable",
            dependencies: [
                "HNSW",
                .product(name: "CoreLMDB", package: "core-lmdb"),
                .product(name: "CoreLMDBCells", package: "core-lmdb"),
                .product(name: "CoreLMDBCoders", package: "core-lmdb")
            ]
        ),
        .target(
            name: "HNSWEphemeral",
            dependencies: ["HNSW"]
        ),
        .target(
            name: "HNSWSample",
            dependencies: ["HNSW", "HNSWEphemeral"]
        ),
        .executableTarget(
            name: "HNSWVisualizer",
            dependencies: ["HNSW", "HNSWSample"]
        ),
        .testTarget(
            name: "HNSWTests",
            dependencies: ["HNSW", "HNSWSample"]
        ),
    ]
)
