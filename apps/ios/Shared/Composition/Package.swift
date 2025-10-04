// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "Composition",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "Composition",
            targets: ["Composition"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Domain"),
        .package(path: "../Data"),
    ],
    targets: [
        .target(
            name: "Composition",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Domain", package: "Domain"),
                .product(name: "Data", package: "Data"),
            ],
            path: "Sources"
        ),
    ]
)
