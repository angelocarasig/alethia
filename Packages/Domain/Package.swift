// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Domain",
    platforms: [.iOS(.v18)],
    products: [.library(name: "Domain", targets: ["Domain"])],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.5.0"),
        .package(path: "../Core")
    ],
    targets: [.target(name: "Domain", dependencies: [
        .product(name: "GRDB", package: "GRDB.swift"),
        "Core"
    ])]
)
