
import Foundation

extension Sequence {
    /// Returns elements from the start of the sequence while an async predicate holds, sequentially.
    ///
    /// Elements are evaluated one at a time in order. Stops at the first element that does not
    /// satisfy the predicate.
    ///
    /// Example:
    /// ```swift
    /// let prefix = try await items.asyncPrefix { try await isValid($0) }
    /// ```
    public func asyncPrefix(
        while predicate: (Element) async throws -> Bool
    ) async rethrows -> [Element] {
        var result: [Element] = []
        for element in self {
            if try await predicate(element) {
                result.append(element)
            } else {
                break
            }
        }
        return result
    }
}
