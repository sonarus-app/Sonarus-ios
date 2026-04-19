// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SonarusCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "SonarusCore",
            targets: ["SonarusCore"]
        )
    ],
    targets: [
        .target(
            name: "SonarusCore"
        ),
        .testTarget(
            name: "SonarusCoreTests",
            dependencies: ["SonarusCore"]
        )
    ]
)
