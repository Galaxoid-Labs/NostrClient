// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "NostrClient",
    platforms: [.iOS(.v17), .macOS(.v14), .macCatalyst(.v17), .visionOS(.v1), .tvOS(.v17), .watchOS(.v10)],
    products: [
        .library(
            name: "NostrClient",
            targets: ["NostrClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Galaxoid-Labs/Nostr.git", branch: "main"),
    ],
    targets: [
        .target(
            name: "NostrClient",
            dependencies: [
                .product(name: "Nostr", package: "Nostr"),
            ]
        ),
        .testTarget(
            name: "NostrClientTests",
            dependencies: ["NostrClient", "Nostr"]),
    ]
)
