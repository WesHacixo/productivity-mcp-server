// swift-tools-version: 5.9
// SwiftPM package for the agentic iOS app. Use Xcode > File > Open Package

import PackageDescription

let package = Package(
    name: "ProductivityAgenticApp",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "ProductivityAgenticApp", targets: ["ProductivityAgenticApp"])
    ],
    dependencies: [
        // MLX Swift package - uncomment when ready
        // .package(url: "https://github.com/ml-explore/mlx-swift.git", from: "0.0.1")
    ],
    targets: [
        .target(
            name: "ProductivityAgenticApp",
            dependencies: [
                // "MLX"
            ],
            path: "Sources"
        ),
        .testTarget(
            name: "ProductivityAgenticAppTests",
            dependencies: ["ProductivityAgenticApp"],
            path: "Tests"
        )
    ]
)
