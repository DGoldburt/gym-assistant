import Foundation

/// A proposal, not a persisted workspace or a claim that a new session is in
/// Notes. The caller supplies the coach-approved outer label. Uncertain headings
/// are separate review items and never appear in generated session content.
public struct SessionSkeleton: Equatable, Sendable {
    public struct HeadingForReview: Equatable, Sendable {
        public let sourceParagraphIndex: Int
        public let paragraph: ProgramParagraph
    }
    public let evidence: SessionSourceEvidence
    public let headingsNeedingReview: [HeadingForReview]

    public init(previous: SessionSourceEvidence, newHeading: String) throws {
        let heading = newHeading.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !heading.isEmpty, !heading.contains(where: { $0.isNewline }),
              ProgramDocument.sessionLabel(heading) != nil,
              let first = previous.paragraphs.first else { throw WorkspaceError.invalidSnapshot }
        let outerLevel = first.headingLevel > 0 ? first.headingLevel : 2
        var paragraphs = [ProgramParagraph(text: heading + "\n", headingLevel: outerLevel)]
        var review: [HeadingForReview] = []
        var unresolvedParentLevel: Int?
        for (index, paragraph) in previous.paragraphs.enumerated().dropFirst() {
            let label = paragraph.label
            // Parking Lot is attached context, including any headings nested
            // beneath it, not structure for the next session.
            if label.lowercased() == "parking lot" { break }
            guard paragraph.headingLevel > 0 else { continue }
            if let level = unresolvedParentLevel {
                if paragraph.headingLevel > level {
                    review.append(HeadingForReview(sourceParagraphIndex: index, paragraph: paragraph))
                    continue
                }
                unresolvedParentLevel = nil
            }
            guard Self.isStructural(label), paragraph.headingLevel > outerLevel else {
                review.append(HeadingForReview(sourceParagraphIndex: index, paragraph: paragraph))
                unresolvedParentLevel = paragraph.headingLevel
                continue
            }
            // Rebuild semantic paragraphs instead of carrying old inline marks,
            // links, lists or invisible prescription-bearing attributes forward.
            paragraphs.append(ProgramParagraph(text: label + "\n", headingLevel: paragraph.headingLevel))
        }
        evidence = SessionSourceEvidence(paragraphs: paragraphs)
        headingsNeedingReview = review
    }

    private static func isStructural(_ label: String) -> Bool {
        let names: Set<String> = ["warmup", "warm-up", "warm up", "preparation", "main work",
            "strength", "power", "conditioning", "accessories", "accessory work", "finisher",
            "cooldown", "cool-down", "cool down", "mobility"]
        if names.contains(label.lowercased()) { return true }
        // Exact bare block/slot/week labels only. "A1 Row", "Week 1 — heavy"
        // and other content-bearing headings must be reviewed, not guessed.
        return label.range(of: #"^(?:[A-Z](?:[1-9][0-9]*)?|Block [A-Z0-9]+|Week [1-9][0-9]*)$"#,
                           options: [.regularExpression, .caseInsensitive]) != nil
    }
}
