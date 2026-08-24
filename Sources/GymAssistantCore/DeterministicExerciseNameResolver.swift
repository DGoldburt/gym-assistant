public struct DeterministicExerciseNameResolver: Sendable {
    private let normalizer: BasicExerciseNameNormalizer

    public init(normalizer: BasicExerciseNameNormalizer = .init()) {
        self.normalizer = normalizer
    }

    public func matchesConfirmedName(query: String, confirmedNames: [String]) throws -> Bool {
        if confirmedNames.contains(query) {
            return true
        }

        let normalizedQuery = try normalizer.normalize(query)
        return try confirmedNames.contains {
            try normalizer.normalize($0) == normalizedQuery
        }
    }
}
