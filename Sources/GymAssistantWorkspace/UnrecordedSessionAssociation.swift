import Foundation

/// Exact insertion evidence only. Formatting differences, other Notes edits and
/// missing origin evidence require review; labels alone never establish identity.
public enum UnrecordedSessionAssociation {
    public enum Result: Equatable, Sendable {
        case notInserted
        case needsReview
        case verified(SourceRange)
    }

    public static func evaluate(anchor: SessionAnchor, scratchpad: SessionSourceEvidence,
                                document: ProgramDocument) -> Result {
        guard anchor.isUnrecorded, anchor.noteID == document.snapshot.id,
              let origin = anchor.unrecordedOrigin else { return .needsReview }
        if origin.paragraphs == document.paragraphs { return .notInserted }
        let candidates = document.candidates()
        let labels = candidates.compactMap { ProgramDocument.sessionLabel($0.label) }
        guard Set(labels).count == labels.count else { return .needsReview }
        let matches = candidates.filter { candidate in
            guard !candidate.needsClassification,
                  candidate.evidence.paragraphs.map(visibleFormatting) == scratchpad.paragraphs.map(visibleFormatting) else { return false }
            let remaining = zip(document.paragraphs, document.ranges).filter { _, range in
                NSIntersectionRange(range.nsRange, candidate.range.nsRange).length == 0
            }.map { $0.0 }
            return remaining == origin.paragraphs
        }
        guard matches.count == 1, let match = matches.first else { return .needsReview }
        return .verified(match.range)
    }

    /// AppKit may style the terminating newline while Notes leaves it unstyled.
    /// Keep the paragraph and every visible mark; ignore only marks on its newline.
    private static func visibleFormatting(_ paragraph: ProgramParagraph) -> ProgramParagraph {
        var visible = paragraph.text
        while visible.last?.isNewline == true { visible.removeLast() }
        let length = (visible as NSString).length
        let marks = paragraph.marks.compactMap { mark -> ProgramParagraph.Mark? in
            let end = min(mark.range.location + mark.range.length, length)
            guard end > mark.range.location else { return nil }
            return .init(range: SourceRange(location: mark.range.location, length: end - mark.range.location),
                         kind: mark.kind, value: mark.value)
        }
        return ProgramParagraph(text: paragraph.text, headingLevel: paragraph.headingLevel,
                                listStyle: paragraph.listStyle, marks: marks)
    }
}
