// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GymAssistant",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "GymAssistantCore", targets: ["GymAssistantCore"]),
        .executable(name: "ResolverFixtureRunner", targets: ["ResolverFixtureRunner"]),
        .executable(name: "IdentityReviewFixtureRunner", targets: ["IdentityReviewFixtureRunner"]),
        .executable(name: "PersonalLibraryImport", targets: ["PersonalLibraryImport"]),
        .executable(name: "GymAssistantNotesService", targets: ["GymAssistantNotesService"]),
        .executable(name: "FieldFeedbackReport", targets: ["FieldFeedbackReport"]),
        .executable(name: "SetFieldFeedbackDisposition", targets: ["SetFieldFeedbackDisposition"]),
    ],
    targets: [
        .target(name: "GymAssistantCore", linkerSettings: [.linkedLibrary("sqlite3")]),
        .executableTarget(name: "ResolverFixtureRunner", dependencies: ["GymAssistantCore"]),
        .executableTarget(name: "IdentityReviewFixtureRunner", dependencies: ["GymAssistantCore"]),
        .executableTarget(name: "PersonalLibraryImport", dependencies: ["GymAssistantCore"]),
        .executableTarget(
            name: "GymAssistantNotesService",
            dependencies: ["GymAssistantCore"],
            linkerSettings: [.linkedFramework("AppKit")]
        ),
        .executableTarget(name: "FieldFeedbackReport", dependencies: ["GymAssistantCore"]),
        .executableTarget(name: "SetFieldFeedbackDisposition", dependencies: ["GymAssistantCore"]),
        .testTarget(name: "GymAssistantCoreTests", dependencies: ["GymAssistantCore"]),
    ]
)
