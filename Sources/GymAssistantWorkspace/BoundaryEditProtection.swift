import Foundation

public enum BoundaryChangeError: Error, Equatable { case invalidEdit, editedRegion, uncertainCorrespondence, staleSource }
public struct BoundaryTextChange: Equatable, Sendable {
    public let removePrefix: Int
    public let removeSuffix: Int
    public let prepend: SourceRange?
    public let append: SourceRange?
}

/// Tracks only correspondence needed to protect boundary edits, not coaching
/// preference provenance. Deleted source units remain protected after disappearing.
public struct BoundaryEditProtection: Codable, Equatable, Sendable {
    public private(set) var sourceRange: SourceRange
    private var origins: [Int?]
    private var protected: Set<Int> = []
    private var uncertain = false

    public init(sourceRange: SourceRange) {
        self.sourceRange = sourceRange
        origins = []
        if sourceRange.location >= 0 && sourceRange.length > 0 && sourceRange.location <= Int.max - sourceRange.length {
            origins = (sourceRange.location..<(sourceRange.location + sourceRange.length)).map { $0 }
        } else { uncertain = true }
    }

    public mutating func edited(range: NSRange, replacementLength: Int) throws {
        guard range.location >= 0, range.length >= 0, replacementLength >= 0,
              range.location <= origins.count, range.length <= origins.count - range.location else {
            uncertain = true; throw BoundaryChangeError.invalidEdit
        }
        let affected = origins[range.location..<(range.location + range.length)].compactMap { $0 }
        protected.formUnion(affected)
        if replacementLength > 0 {
            // An insertion exactly at a source boundary belongs to an adjacent
            // source unit, preventing it from being lost when that edge shrinks.
            let next = origins.dropFirst(range.location).compactMap { $0 }.first
            let previous = origins.prefix(range.location).compactMap { $0 }.last
            if let anchor = next ?? previous { protected.insert(anchor) }
            else { uncertain = true }
        }
        origins.replaceSubrange(range.location..<(range.location + range.length),
                                with: Array(repeating: nil, count: replacementLength))
    }

    public mutating func formattingChanged(range: NSRange) throws {
        guard range.location >= 0, range.length >= 0, range.location <= origins.count,
              range.length <= origins.count - range.location else {
            uncertain = true; throw BoundaryChangeError.invalidEdit
        }
        protected.formUnion(origins[range.location..<(range.location + range.length)].compactMap { $0 })
    }

    public mutating func markUncertain(currentLength: Int? = nil) {
        uncertain = true
        if let currentLength { origins = Array(repeating: nil, count: max(0, currentLength)) }
    }

    public func isValid(currentLength: Int) -> Bool {
        guard sourceRange.location >= 0, sourceRange.length > 0,
              sourceRange.location <= Int.max - sourceRange.length, origins.count == currentLength else { return false }
        let end = sourceRange.location + sourceRange.length
        return origins.compactMap { $0 }.allSatisfy { $0 >= sourceRange.location && $0 < end }
            && protected.allSatisfy { $0 >= sourceRange.location && $0 < end }
    }

    /// Preview only. Caller validates the fresh observation and ownership before
    /// applying text and the returned tracker together as one undoable operation.
    public func preview(_ next: SourceRange, in source: String) throws -> BoundaryTextChange {
        guard next.isParagraphAligned(in: source), sourceRange.isParagraphAligned(in: source) else {
            throw BoundaryChangeError.staleSource
        }
        let oldEnd = NSMaxRange(sourceRange.nsRange), nextEnd = NSMaxRange(next.nsRange)
        let shrinking = next.location > sourceRange.location || nextEnd < oldEnd
        if shrinking && uncertain { throw BoundaryChangeError.uncertainCorrespondence }
        guard NSIntersectionRange(next.nsRange, sourceRange.nsRange).length > 0 else { throw BoundaryChangeError.invalidEdit }
        if protected.contains(where: { $0 < next.location || $0 >= nextEnd }) { throw BoundaryChangeError.editedRegion }
        let prefix = origins.prefix { origin in origin.map { $0 < next.location } ?? false }.count
        let suffix = origins.reversed().prefix { origin in origin.map { $0 >= nextEnd } ?? false }.count
        return BoundaryTextChange(removePrefix: prefix, removeSuffix: suffix,
            prepend: next.location < sourceRange.location ? SourceRange(location: next.location, length: sourceRange.location - next.location) : nil,
            append: nextEnd > oldEnd ? SourceRange(location: oldEnd, length: nextEnd - oldEnd) : nil)
    }

    public mutating func apply(_ next: SourceRange, in source: String) throws -> BoundaryTextChange {
        let change = try preview(next, in: source)
        if change.removeSuffix > 0 { origins.removeLast(change.removeSuffix) }
        if change.removePrefix > 0 { origins.removeFirst(change.removePrefix) }
        if let prefix = change.prepend {
            origins.insert(contentsOf: (prefix.location..<NSMaxRange(prefix.nsRange)).map { $0 }, at: 0)
        }
        if let suffix = change.append { origins.append(contentsOf: (suffix.location..<NSMaxRange(suffix.nsRange)).map { $0 }) }
        sourceRange = next
        return change
    }
}
