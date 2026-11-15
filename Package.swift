// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Sandman",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Sandman",
            path: "Sources/Sandman"
        )
    ]
)
