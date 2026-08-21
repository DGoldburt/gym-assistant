// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GymAssistant",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "GymAssistantCore", targets: ["GymAssistantCore"]),
    ],
    targets: [
        .target(name: "GymAssistantCore", linkerSettings: [.linkedLibrary("sqlite3")]),
        .testTarget(name: "GymAssistantCoreTests", dependencies: ["GymAssistantCore"]),
    ]
)
