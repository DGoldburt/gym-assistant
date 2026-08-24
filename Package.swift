// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GymAssistant",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "GymAssistantCore", targets: ["GymAssistantCore"]),
        .executable(name: "ResolverFixtureRunner", targets: ["ResolverFixtureRunner"]),
    ],
    targets: [
        .target(name: "GymAssistantCore", linkerSettings: [.linkedLibrary("sqlite3")]),
        .executableTarget(name: "ResolverFixtureRunner", dependencies: ["GymAssistantCore"]),
        .testTarget(name: "GymAssistantCoreTests", dependencies: ["GymAssistantCore"]),
    ]
)
