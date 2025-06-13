// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Core",
    platforms: [.iOS(.v18)],
    products: [.library(name: "Core", targets: ["Core"])],
    targets: [.target(name: "Core")]
)
