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
        .executable(
            name: "SmallWorldVisualizer",
            targets: ["SmallWorldVisualizer"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/jadengeller/CoreLMDB.git", branch: "main"),
        .package(url: "https://github.com/JadenGeller/swift-priority-heap", branch: "release/0.4.3"),
        .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SmallWorld",
            dependencies: [
                "CoreLMDB",
                .product(name: "PriorityHeapModule", package: "swift-priority-heap"),
                .product(name: "PriorityHeapAlgorithms", package: "swift-priority-heap"),
                .product(name: "RealModule", package: "swift-numerics"),
            ]
        ),
        .executableTarget(
            name: "SmallWorldVisualizer",
            dependencies: ["SmallWorld"]
        ),
        .testTarget(
            name: "SmallWorldTests",
            dependencies: ["SmallWorld"]
        ),
    ]
)
