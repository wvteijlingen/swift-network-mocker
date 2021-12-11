// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "moya-stubber",
    platforms: [
        .macOS("10.12"),
        .iOS(.v10)
    ],
    products: [
        .library(name: "MoyaStubber", type: nil, targets: ["MoyaStubber"])
    ],
    dependencies: [
        .package(url: "https://github.com/Moya/Moya.git", .upToNextMajor(from: "15.0.0"))
    ],
    targets: [
        .target(name: "MoyaStubber", dependencies: ["Moya"]),
        .testTarget(
            name: "MoyaStubberTests",
            dependencies: ["MoyaStubber"],
            resources: [.copy("Stubs.bundle"), .copy("EmptyBundle.bundle")]
        )
    ]
)

