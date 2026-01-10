// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CasaCLI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "casa", targets: ["CasaCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "CasaCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        )
    ]
)
