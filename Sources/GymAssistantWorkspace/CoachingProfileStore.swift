import Foundation

public enum CoachingProfileLoadError: Error, Equatable {
    case unavailable, invalid, oversized
}

/// Read-only, private local configuration; never synthesizes an empty fallback.
public enum CoachingProfileStore {
    public static var applicationURL: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("GymAssistant/coaching-profile.json")
    }
    public static func load(from url: URL = applicationURL) throws -> CoachingProfile {
        guard let handle = try? FileHandle(forReadingFrom: url) else { throw CoachingProfileLoadError.unavailable }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: 100_001) else { throw CoachingProfileLoadError.unavailable }
        return try decode(data)
    }
    public static func decode(_ data: Data) throws -> CoachingProfile {
        guard data.count <= 100_000 else { throw CoachingProfileLoadError.oversized }
        guard let profile = try? JSONDecoder().decode(CoachingProfile.self, from: data),
              !profile.version.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !profile.entries.isEmpty,
              profile.entries.allSatisfy({ !$0.wording.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                  && !$0.source.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
        else { throw CoachingProfileLoadError.invalid }
        return profile
    }
}
