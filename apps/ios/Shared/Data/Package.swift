// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "Data",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "Data",
            targets: ["Data"]),
    ],
    dependencies: [
        .package(path: "../Core"),
        .package(path: "../Domain"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.7.0"),
        .package(url: "https://github.com/pointfreeco/swift-tagged", from: "0.10.0")
    ],
    targets: [
        .target(
            name: "Data",
            dependencies: [
                .product(name: "Core", package: "Core"),
                .product(name: "Domain", package: "Domain"),
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "Tagged", package: "swift-tagged")
            ],
            path: "Sources"
        ),
    ]
)
