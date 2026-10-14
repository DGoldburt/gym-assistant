import Foundation
import Testing
@testable import GymAssistantWorkspace

@Suite("Boundary edit protection") struct BoundaryEditProtectionTests {
    let source = "Before\nSession 1\nA1 Row\nB1 Press\nAfter\n"
    var initial: SourceRange { SourceRange(location: 7, length: 26) }

    @Test func expandsOnlyEdgesAndPreservesMiddleEdits() throws {
        var tracker = BoundaryEditProtection(sourceRange: initial)
        try tracker.edited(range: NSRange(location: 10, length: 6), replacementLength: 14)
        let expanded = SourceRange(location: 0, length: (source as NSString).length)
        let change = try tracker.apply(expanded, in: source)
        #expect(change.removePrefix == 0 && change.removeSuffix == 0)
        #expect(change.prepend == SourceRange(location: 0, length: 7))
        #expect(change.append == SourceRange(location: 33, length: 6))
    }

    @Test func shrinkingUntouchedEdgeDoesNotDiscardMiddleEdit() throws {
        var tracker = BoundaryEditProtection(sourceRange: initial)
        try tracker.edited(range: NSRange(location: 10, length: 6), replacementLength: 14)
        let change = try tracker.preview(SourceRange(location: 7, length: 17), in: source)
        #expect(change.removeSuffix == 9)
    }

    @Test func deletedTextStillBlocksShrink() throws {
        var tracker = BoundaryEditProtection(sourceRange: initial)
        try tracker.edited(range: NSRange(location: 17, length: 9), replacementLength: 0)
        #expect(throws: BoundaryChangeError.editedRegion) {
            try tracker.preview(SourceRange(location: 7, length: 17), in: source)
        }
    }

    @Test func addedAndFormattedTextBlockShrink() throws {
        var tracker = BoundaryEditProtection(sourceRange: initial)
        try tracker.edited(range: NSRange(location: 26, length: 0), replacementLength: 12)
        #expect(throws: BoundaryChangeError.editedRegion) {
            try tracker.preview(SourceRange(location: 7, length: 17), in: source)
        }
        tracker = BoundaryEditProtection(sourceRange: initial)
        try tracker.formattingChanged(range: NSRange(location: 17, length: 2))
        #expect(throws: BoundaryChangeError.editedRegion) {
            try tracker.preview(SourceRange(location: 7, length: 17), in: source)
        }
    }

    @Test func uncertainCorrespondenceAllowsExpansionButNotShrink() throws {
        var tracker = BoundaryEditProtection(sourceRange: initial)
        tracker.markUncertain()
        #expect(throws: BoundaryChangeError.uncertainCorrespondence) {
            try tracker.preview(SourceRange(location: 7, length: 17), in: source)
        }
        #expect(try tracker.preview(SourceRange(location: 0, length: 39), in: source).prepend != nil)
    }
}
