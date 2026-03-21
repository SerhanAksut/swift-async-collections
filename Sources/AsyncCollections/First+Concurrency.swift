
import Foundation

extension Sequence {
    /// Returns the first element satisfying an async predicate, sequentially.
    ///
    /// Elements are evaluated one at a time in order. Short-circuits on the first match.
    /// For parallel evaluation, use `concurrentFirst(where:)`.
    ///
    /// Example:
    /// ```swift
    /// let admin = try await users.asyncFirst { try await checkIsAdmin($0) }
    /// ```
    public func asyncFirst(
        where predicate: (Element) async throws -> Bool
    ) async rethrows -> Element? {
        for element in self {
            if try await predicate(element) {
                return element
            }
        }
        return nil
    }

    /// Returns the first element satisfying an async predicate, concurrently, while preserving order.
    ///
    /// Uses structured concurrency via `TaskGroup`. Predicates are evaluated in parallel,
    /// but the result is the first matching element by original sequence order. Cancels remaining
    /// tasks once the earliest match is confirmed.
    ///
    /// Example:
    /// ```swift
    /// let admin = await users.concurrentFirst { await checkIsAdmin($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - maxNumberOfTasks: Maximum number of tasks running in parallel. `nil` means unlimited.
    ///   - priority: Task priority (default: inherits from parent)
    ///   - predicate: Async predicate closure to evaluate each element
    public func concurrentFirst(
        maxNumberOfTasks: Int? = nil,
        priority: TaskPriority? = nil,
        where predicate: @escaping @Sendable (Element) async -> Bool
    ) async -> Element? where Element: Sendable {
        await withTaskGroup(of: (Int, Element?).self) { group in
            var bestMatch: (index: Int, element: Element)? = nil
            var completedUpTo = Set<Int>()
            for (index, element) in enumerated() {
                if let max = maxNumberOfTasks, index >= max {
                    if let (resultIndex, resultElement) = await group.next() {
                        completedUpTo.insert(resultIndex)
                        if let element = resultElement {
                            if bestMatch == nil || resultIndex < bestMatch!.index {
                                bestMatch = (resultIndex, element)
                            }
                        }
                        if let best = bestMatch, (0..<best.index).allSatisfy({ completedUpTo.contains($0) }) {
                            group.cancelAll()
                            return best.element
                        }
                    }
                }
                group.addTask(priority: priority) {
                    await (index, predicate(element) ? element : nil)
                }
            }
            for await (resultIndex, resultElement) in group {
                completedUpTo.insert(resultIndex)
                if let element = resultElement {
                    if bestMatch == nil || resultIndex < bestMatch!.index {
                        bestMatch = (resultIndex, element)
                    }
                }
                if let best = bestMatch, (0..<best.index).allSatisfy({ completedUpTo.contains($0) }) {
                    group.cancelAll()
                    return best.element
                }
            }
            return bestMatch?.element
        }
    }

    /// Returns the first element satisfying an async predicate, concurrently, while preserving order.
    /// Throws on first error.
    ///
    /// Uses structured concurrency via `ThrowingTaskGroup`. Predicates are evaluated in parallel,
    /// but the result is the first matching element by original sequence order. Cancels remaining
    /// tasks once the earliest match is confirmed. If any predicate throws, remaining tasks
    /// are cancelled automatically.
    ///
    /// Example:
    /// ```swift
    /// let admin = try await users.concurrentFirst { try await checkIsAdmin($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - maxNumberOfTasks: Maximum number of tasks running in parallel. `nil` means unlimited.
    ///   - priority: Task priority (default: inherits from parent)
    ///   - predicate: Async throwing predicate closure to evaluate each element
    public func concurrentFirst(
        maxNumberOfTasks: Int? = nil,
        priority: TaskPriority? = nil,
        where predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async throws -> Element? where Element: Sendable {
        try await withThrowingTaskGroup(of: (Int, Element?).self) { group in
            var bestMatch: (index: Int, element: Element)? = nil
            var completedUpTo = Set<Int>()
            for (index, element) in enumerated() {
                if let max = maxNumberOfTasks, index >= max {
                    if let (resultIndex, resultElement) = try await group.next() {
                        completedUpTo.insert(resultIndex)
                        if let element = resultElement {
                            if bestMatch == nil || resultIndex < bestMatch!.index {
                                bestMatch = (resultIndex, element)
                            }
                        }
                        if let best = bestMatch, (0..<best.index).allSatisfy({ completedUpTo.contains($0) }) {
                            group.cancelAll()
                            return best.element
                        }
                    }
                }
                group.addTask(priority: priority) {
                    try await (index, predicate(element) ? element : nil)
                }
            }
            for try await (resultIndex, resultElement) in group {
                completedUpTo.insert(resultIndex)
                if let element = resultElement {
                    if bestMatch == nil || resultIndex < bestMatch!.index {
                        bestMatch = (resultIndex, element)
                    }
                }
                if let best = bestMatch, (0..<best.index).allSatisfy({ completedUpTo.contains($0) }) {
                    group.cancelAll()
                    return best.element
                }
            }
            return bestMatch?.element
        }
    }
}
