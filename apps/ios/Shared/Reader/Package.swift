// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Reader",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "Reader",
            targets: ["Reader"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/ekazaev/ChatLayout.git", .upToNextMajor(from: "2.3.1")),
        .package(url: "https://github.com/onevcat/Kingfisher.git", .upToNextMajor(from: "8.0.0")),
        .package(url: "https://github.com/angelocarasig/Texture.git", .upToNextMajor(from: "3.2.0"))
    ],
    targets: [
        .target(
            name: "Reader",
            dependencies: [
                .product(name: "ChatLayout", package: "ChatLayout"),
                "Kingfisher",
                .product(name: "AsyncDisplayKit", package: "Texture")
            ],
            path: "Sources"
        )
    ]
)
