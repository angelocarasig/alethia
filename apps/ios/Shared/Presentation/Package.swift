// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Presentation",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "Presentation",
            targets: ["Presentation"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Domain"),
        .package(path: "../Composition"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "8.0.0")),
        .package(url: "https://github.com/tevelee/SwiftUI-Flow.git", from: "3.1.0")
    ],
    targets: [
        .target(
            name: "Presentation",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Domain", package: "Domain"),
                .product(name: "Composition", package: "Composition"),
                "Kingfisher",
                .product(name: "Flow", package: "SwiftUI-Flow")
            ],
            path: "Sources"
        ),
    ]
)
