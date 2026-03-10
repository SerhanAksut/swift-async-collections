
import Foundation

extension Sequence {
    /// Filters elements sequentially using an async predicate.
    ///
    /// Elements are evaluated one at a time in order. For parallel evaluation, use `concurrentFilter`.
    ///
    /// Example:
    /// ```swift
    /// let activeUsers = try await users.asyncFilter { try await checkIsActive($0) }
    /// ```
    public func asyncFilter(
        _ isIncluded: (Element) async throws -> Bool
    ) async rethrows -> [Element] {
        var result: [Element] = []
        for element in self {
            if try await isIncluded(element) {
                result.append(element)
            }
        }
        return result
    }

    /// Filters elements concurrently using an async predicate while preserving order.
    ///
    /// Uses structured concurrency via `TaskGroup` for proper cancellation propagation.
    ///
    /// Example:
    /// ```swift
    /// let activeUsers = await users.concurrentFilter { await checkIsActive($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - maxNumberOfTasks: Maximum number of tasks running in parallel. `nil` means unlimited.
    ///   - priority: Task priority (default: inherits from parent)
    ///   - isIncluded: Async predicate closure returning whether to include the element
    public func concurrentFilter(
        maxNumberOfTasks: Int? = nil,
        priority: TaskPriority? = nil,
        _ isIncluded: @escaping @Sendable (Element) async -> Bool
    ) async -> [Element] where Element: Sendable {
        await withTaskGroup(of: (Int, Element?).self) { group in
            var results: [(Int, Element?)] = []
            for (index, element) in enumerated() {
                if let max = maxNumberOfTasks, index >= max {
                    if let result = await group.next() {
                        results.append(result)
                    }
                }
                group.addTask(priority: priority) {
                    await (index, isIncluded(element) ? element : nil)
                }
            }
            for await result in group {
                results.append(result)
            }
            return results
                .sorted { $0.0 < $1.0 }
                .compactMap(\.1)
        }
    }

    /// Filters elements concurrently using an async predicate while preserving order. Throws on first error.
    ///
    /// Uses structured concurrency via `ThrowingTaskGroup` for proper cancellation propagation.
    /// If any predicate throws, remaining tasks are cancelled automatically.
    ///
    /// Example:
    /// ```swift
    /// let activeUsers = try await users.concurrentFilter { try await checkIsActive($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - maxNumberOfTasks: Maximum number of tasks running in parallel. `nil` means unlimited.
    ///   - priority: Task priority (default: inherits from parent)
    ///   - isIncluded: Async throwing predicate closure returning whether to include the element
    public func concurrentFilter(
        maxNumberOfTasks: Int? = nil,
        priority: TaskPriority? = nil,
        _ isIncluded: @escaping @Sendable (Element) async throws -> Bool
    ) async throws -> [Element] where Element: Sendable {
        try await withThrowingTaskGroup(of: (Int, Element?).self) { group in
            var results: [(Int, Element?)] = []
            for (index, element) in enumerated() {
                if let max = maxNumberOfTasks, index >= max {
                    if let result = try await group.next() {
                        results.append(result)
                    }
                }
                group.addTask(priority: priority) {
                    try await (index, isIncluded(element) ? element : nil)
                }
            }
            for try await result in group {
                results.append(result)
            }
            return results
                .sorted { $0.0 < $1.0 }
                .compactMap(\.1)
        }
    }
}
