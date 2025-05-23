// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.


import PackageDescription


let package = Package(
    name: "IBKit",
	defaultLocalization: "en",
    platforms: [
        .macOS(.v12), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1)
    ],
    products: [
        .library(
			name: "IBKit",
			targets: ["IBKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio", from: .init(2, 0, 0))
	],
    targets: [
        .target(
			name: "IBKit",
			dependencies: [
                .product(name: "NIO", package: "swift-nio")
            ],
			path: "IBKit/IBKit"),
        .testTarget(
			name: "IBKitTests",
			dependencies: ["IBKit"],
			path: "IBKit/IBKitTests")
    ]
)
