// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "NostrClient",
    platforms: [.iOS(.v16), .macOS(.v13), .macCatalyst(.v16), .visionOS(.v1)],
    products: [
        .library(
            name: "NostrClient",
            targets: ["NostrClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Galaxoid-Labs/Nostr.git", branch: "main"),
        .package(url: "https://github.com/Galaxoid-Labs/Starscream.git", branch: "linux_fix")
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
