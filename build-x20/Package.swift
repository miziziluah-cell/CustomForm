// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CustomForm",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "CustomForm", targets: ["CustomForm"])
    ],
    targets: [
        .executableTarget(name: "CustomForm")
    ]
)
