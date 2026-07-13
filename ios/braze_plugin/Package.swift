// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "braze_plugin",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "braze-plugin",
            targets: ["braze_plugin"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/braze-inc/braze-swift-sdk",
            from: "17.0.0"
        )
    ],
    targets: [
        .target(
            name: "braze_plugin",
            dependencies: [
                .product(name: "BrazeKit", package: "braze-swift-sdk"),
                .product(name: "BrazeLocation", package: "braze-swift-sdk"),
                .product(name: "BrazeUI", package: "braze-swift-sdk")
            ],
            exclude: [
                "BrazeFlutterPlugin/BrazeFlutterPluginTests",
                "BrazeFlutterPlugin/BrazeFlutterPluginTests.xctestplan"
            ],
            resources: []
        ),
        .testTarget(
            name: "BrazeFlutterPluginTests",
            dependencies: ["braze_plugin"],
            path: "Sources/braze_plugin/BrazeFlutterPlugin/BrazeFlutterPluginTests"
        )
    ]
)
