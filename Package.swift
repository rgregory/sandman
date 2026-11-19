// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Sandman",
    platforms: [.macOS(.v14)],
    dependencies: [
        // The look lives next door: ThemeMonkey owns the tokens and the drawing recipe,
        // Sandman is its first consumer. Local path while neither is pushed; swap for
        // .package(url:from:) once ThemeMonkey has a remote and a tag.
        .package(path: "../Monkeys/ThemeMonkey")
    ],
    targets: [
        .executableTarget(
            name: "Sandman",
            dependencies: ["ThemeMonkey"],
            path: "Sources/Sandman"
        )
    ]
)
