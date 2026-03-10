
import Foundation

extension Sequence {
    /// Combines elements sequentially into a single value using an async closure.
    ///
    /// Each element is processed one at a time in order, passing the accumulated result forward.
    ///
    /// Example:
    /// ```swift
    /// let total = try await invoices.asyncReduce(0) { sum, invoice in
    ///     try await sum + fetchAmount(for: invoice)
    /// }
    /// ```
    public func asyncReduce<Result>(
        _ initialResult: Result,
        _ nextPartialResult: (Result, Element) async throws -> Result
    ) async rethrows -> Result {
        var result = initialResult
        for element in self {
            result = try await nextPartialResult(result, element)
        }
        return result
    }

    /// Combines elements sequentially into a single value using an async closure with an inout accumulator.
    ///
    /// Each element is processed one at a time in order. The `inout` accumulator avoids
    /// copying on each iteration, making this more efficient for value types like arrays and dictionaries.
    ///
    /// Example:
    /// ```swift
    /// let usersByID = try await users.asyncReduce(into: [:]) { dict, user in
    ///     dict[user.id] = try await fetchProfile(for: user)
    /// }
    /// ```
    public func asyncReduce<Result>(
        into initialResult: Result,
        _ updateAccumulatingResult: (inout Result, Element) async throws -> Void
    ) async rethrows -> Result {
        var result = initialResult
        for element in self {
            try await updateAccumulatingResult(&result, element)
        }
        return result
    }
}
