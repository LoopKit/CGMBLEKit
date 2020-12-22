// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CGMBLEKit",
    defaultLocalization: "en",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(name: "CGMBLEKit",targets: ["CGMBLEKit"]),
        .library(name: "CGMBLEKitG5Plugin",targets: ["CGMBLEKitG5Plugin"]),
        .library(name: "CGMBLEKitG6Plugin",targets: ["CGMBLEKitG6Plugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/LoopKit/LoopKit.git", .branch("package-experiment")),
        .package(name: "ShareClient", url: "https://github.com/LoopKit/dexcom-share-client-swift.git", .branch("package-experiment")),
        .package(url: "https://github.com/LoopKit/G4ShareSpy.git", .branch("package-experiment")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "CGMBLEKit",
            dependencies: [
                "LoopKit",
                .product(name: "ShareClient", package: "ShareClient")
            ],
            path: "CGMBLEKit",
            exclude: ["Info.plist"]
        ),
        .target(
            name: "CGMBLEKitUI",
            dependencies: [
                "LoopKit",
                .product(name: "ShareClient", package: "ShareClient"),
                .product(name: "ShareClientUI", package: "ShareClient")
            ],
            path: "CGMBLEKitUI",
            exclude: ["Info.plist"]
        ),
        .target(
            name: "CGMBLEKitG5Plugin",
            dependencies: [
                "CGMBLEKit",
                "CGMBLEKitUI",
                .product(name: "LoopKitUI", package: "LoopKit"),
                "LoopKit"],
            path: "CGMBLEKitG5Plugin",
            exclude: ["Info.plist"]
        ),
        .target(
            name: "CGMBLEKitG6Plugin",
            dependencies: [
                "CGMBLEKit",
                "CGMBLEKitUI",
                .product(name: "LoopKitUI", package: "LoopKit"),
                "LoopKit"],
            path: "CGMBLEKitG6Plugin",
            exclude: ["Info.plist"]
        ),
        .testTarget(
            name: "CGMBLEKitTests",
            dependencies: ["CGMBLEKit"],
            path: "CGMBLEKitTests",
            exclude: ["Info.plist"]
        ),
    ]
)
