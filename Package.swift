// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "VoidXGradient",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VoidXGradient", targets: ["VoidXGradient"])
    ],
    targets: [
        .executableTarget(
            name: "VoidXGradient",
            path: "Sources/VoidXGradient"
        )
    ]
)
