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
        .package(path: "../Composition")
    ],
    targets: [
        .target(
            name: "Presentation",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Domain", package: "Domain"),
                .product(name: "Composition", package: "Composition")
            ],
            path: "Sources"
        ),
    ]
)
