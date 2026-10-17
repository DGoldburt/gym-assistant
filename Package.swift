// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "GymAssistant",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ChatGPTConnection", targets: ["ChatGPTConnection"]),
        .library(name: "GymAssistantCore", targets: ["GymAssistantCore"]),
        .library(name: "GymAssistantWorkspace", targets: ["GymAssistantWorkspace"]),
        .library(name: "GymAssistantMacOS", targets: ["GymAssistantMacOS"]),
        .executable(name: "ScratchpadDevelopment", targets: ["ScratchpadDevelopment"]),
        .executable(name: "ResolverFixtureRunner", targets: ["ResolverFixtureRunner"]),
        .executable(name: "IdentityReviewFixtureRunner", targets: ["IdentityReviewFixtureRunner"]),
        .executable(name: "PersonalLibraryImport", targets: ["PersonalLibraryImport"]),
        .executable(name: "GymAssistantNotesService", targets: ["GymAssistantNotesService"]),
        .executable(name: "FieldFeedbackReport", targets: ["FieldFeedbackReport"]),
        .executable(name: "SetFieldFeedbackDisposition", targets: ["SetFieldFeedbackDisposition"]),
    ],
    targets: [
        .target(name: "GymAssistantOpenAI", dependencies: ["GymAssistantWorkspace"]),
        .executableTarget(name: "ChatGPTConnection", dependencies: ["GymAssistantOpenAI"]),
        .testTarget(name: "GymAssistantOpenAITests", dependencies: ["GymAssistantOpenAI"]),
        .target(name: "GymAssistantCore", linkerSettings: [.linkedLibrary("sqlite3")]),
        .target(name: "GymAssistantWorkspace"),
        .target(name: "GymAssistantMacOS", dependencies: ["GymAssistantWorkspace"], linkerSettings: [.linkedFramework("AppKit")]),
        .executableTarget(name: "ScratchpadDevelopment", dependencies: ["GymAssistantWorkspace", "GymAssistantMacOS", "GymAssistantOpenAI"]),
        .testTarget(name: "GymAssistantWorkspaceTests", dependencies: ["GymAssistantWorkspace"]),
        .testTarget(name: "GymAssistantMacOSTests", dependencies: ["GymAssistantWorkspace", "GymAssistantMacOS"]),
        .executableTarget(name: "ResolverFixtureRunner", dependencies: ["GymAssistantCore"]),
        .executableTarget(name: "IdentityReviewFixtureRunner", dependencies: ["GymAssistantCore"]),
        .executableTarget(name: "PersonalLibraryImport", dependencies: ["GymAssistantCore"]),
        .executableTarget(
            name: "GymAssistantNotesService",
            dependencies: ["GymAssistantCore", "GymAssistantMacOS", "GymAssistantWorkspace", "GymAssistantOpenAI"],
            linkerSettings: [.linkedFramework("AppKit")]
        ),
        .executableTarget(name: "FieldFeedbackReport", dependencies: ["GymAssistantCore"]),
        .executableTarget(name: "SetFieldFeedbackDisposition", dependencies: ["GymAssistantCore"]),
        .testTarget(name: "GymAssistantCoreTests", dependencies: ["GymAssistantCore"]),
    ]
)
