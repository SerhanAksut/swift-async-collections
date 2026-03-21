
import Foundation

extension Sequence {
    /// Drops elements from the start of the sequence while an async predicate holds, sequentially.
    ///
    /// Elements are evaluated one at a time in order. Once the predicate returns `false`,
    /// all remaining elements (including the one that failed the predicate) are included
    /// in the result without further evaluation.
    ///
    /// Example:
    /// ```swift
    /// let remaining = try await items.asyncDrop { try await shouldSkip($0) }
    /// ```
    public func asyncDrop(
        while predicate: (Element) async throws -> Bool
    ) async rethrows -> [Element] {
        var result: [Element] = []
        var dropping = true
        for element in self {
            if dropping {
                if try await predicate(element) {
                    continue
                }
                dropping = false
            }
            result.append(element)
        }
        return result
    }
}
