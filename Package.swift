// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "auto-mac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "auto-mac", targets: ["auto-mac"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.7.1"),
        .package(url: "https://github.com/jpsim/Yams", from: "6.2.1"),
        .package(url: "https://github.com/swiftlang/swift-markdown", branch: "main"),
    ],
    targets: [
        .executableTarget(
            name: "auto-mac",
            dependencies: [
                "AutoMacCore",
                "MailModule",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "AutoMacCore",
            dependencies: [
                "Yams",
                .product(name: "Markdown", package: "swift-markdown"),
            ]
        ),
        .target(
            name: "MailModule",
            dependencies: [
                "AutoMacCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "AutoMacCoreTests",
            dependencies: ["AutoMacCore"]
        ),
        .testTarget(
            name: "MailModuleTests",
            dependencies: ["MailModule"]
        ),
    ]
)
