// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-network-mocker",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "NetworkMocker", type: nil, targets: ["NetworkMocker"])
    ],
    targets: [
        .target(name: "NetworkMocker"),
        .testTarget(
            name: "NetworkMockerTests",
            dependencies: ["NetworkMocker"],
            resources: [.copy("EmptyBundle.bundle"), .copy("Mocks.bundle")]
        )
    ]
)

