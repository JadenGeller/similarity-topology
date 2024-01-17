// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "similarity-topology",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SimilarityMetric",
            targets: ["SimilarityMetric"]
        ),
        .library(
            name: "HNSWAlgorithm",
            targets: ["HNSWAlgorithm"]
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
        .package(url: "https://github.com/JadenGeller/swift-priority-heap", from: "0.5.0"),
        .package(url: "https://github.com/jadengeller/core-lmdb.git", from: "0.1.9"),
    ],
    targets: [
        .target(
            name: "SimilarityMetric"
        ),
        .target(
            name: "HNSWAlgorithm",
            dependencies: [
                "SimilarityMetric",
                .product(name: "PriorityHeapModule", package: "swift-priority-heap"),
                .product(name: "PriorityHeapAlgorithms", package: "swift-priority-heap"),
                .product(name: "RealModule", package: "swift-numerics"),
            ]
        ),
        .target(
            name: "HNSWDurable",
            dependencies: [
                "HNSWAlgorithm",
                .product(name: "CoreLMDB", package: "core-lmdb"),
                .product(name: "CoreLMDBCells", package: "core-lmdb"),
                .product(name: "CoreLMDBCoders", package: "core-lmdb")
            ]
        ),
        .target(
            name: "HNSWEphemeral",
            dependencies: ["HNSWAlgorithm"]
        ),
        .target(
            name: "HNSWSample",
            dependencies: ["HNSWAlgorithm", "HNSWEphemeral"]
        ),
        .executableTarget(
            name: "HNSWVisualizer",
            dependencies: ["HNSWAlgorithm", "HNSWSample"]
        ),
        .testTarget(
            name: "HNSWTests",
            dependencies: ["HNSWAlgorithm", "HNSWSample"]
        ),
    ]
)
