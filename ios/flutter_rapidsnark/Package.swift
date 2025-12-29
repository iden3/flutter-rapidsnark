// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_rapidsnark",
    platforms: [
        .iOS("12.0"),
        .macOS("10.14")
    ],
    products: [
        .library(name: "flutter-rapidsnark", targets: ["flutter_rapidsnark"])
    ],
    dependencies: [
        .package(url: "https://github.com/iden3/ios-rapidsnark.git", from: "0.0.1-beta.2")
    ],
    targets: [
        .target(
            name: "flutter_rapidsnark",
            dependencies: [
                .product(name: "rapidsnark", package: "ios-rapidsnark")
            ],
            resources: []
        )
    ]
)
