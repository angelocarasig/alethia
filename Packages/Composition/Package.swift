// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Composition",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "Composition",
            targets: ["Composition"]
        ),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Domain"),
        .package(path: "../Data"),
        // .package(path: "../Presentation"), // TODO: Add when Presentation package is ready
    ],
    targets: [
        .target(
            name: "Composition",
            dependencies: [
                "Core",
                "Domain",
                "Data",
                // "Presentation", // TODO: Add when Presentation package is ready
            ]
        )
    ]
)
