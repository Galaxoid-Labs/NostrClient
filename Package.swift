// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "NostrClient",
    platforms: [.iOS(.v16), .macOS(.v13), .macCatalyst(.v16)],
    products: [
        .library(
            name: "NostrClient",
            targets: ["NostrClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Galaxoid-Labs/Nostr.git", branch: "main"),
        .package(url: "https://github.com/daltoniam/Starscream.git", from: "4.0.8")
    ],
    targets: [
        .target(
            name: "NostrClient",
            dependencies: [
                .product(name: "Nostr", package: "Nostr"),
                .product(name: "Starscream", package: "Starscream")
            ]
        ),
        .testTarget(
            name: "NostrClientTests",
            dependencies: ["NostrClient", "Nostr"]),
    ]
)
