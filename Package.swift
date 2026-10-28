// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Tuckii",
    platforms: [
        .iOS(.v16),
        .macOS(.v14),
    ],
    products: [
        .executable(name: "TuckiiApp", targets: ["TuckiiApp"]),
        .library(name: "TuckiiUI", targets: ["TuckiiUI"]),
        .library(name: "TuckiiCore", targets: ["TuckiiCore"]),
    ],
    targets: [
        .executableTarget(
            name: "TuckiiApp",
            dependencies: ["TuckiiUI", "TuckiiCore"]
        ),
        .target(
            name: "TuckiiUI",
            dependencies: ["TuckiiCore"]
        ),
        .target(name: "TuckiiCore"),
        .testTarget(
            name: "TuckiiCoreTests",
            dependencies: ["TuckiiCore"]
        ),
    ]
)
