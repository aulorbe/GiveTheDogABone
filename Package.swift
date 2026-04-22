// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "NotionMenuBarTracker",
    platforms: [.macOS(.v13)],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "NotionMenuBarTracker",
            dependencies: [],
            path: "Sources"
        )
    ]
)
