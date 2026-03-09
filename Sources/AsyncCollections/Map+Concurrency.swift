
import Foundation

extension Sequence {
    /// Transforms each element sequentially using an async closure.
    ///
    /// Elements are processed one at a time in order. For parallel processing, use `concurrentMap`.
    ///
    /// Example:
    /// ```swift
    /// let data = try await urls.asyncMap { try await URLSession.shared.data(from: $0).0 }
    /// ```
    public func asyncMap<Value>(
        _ transform: (Element) async throws -> Value
    ) async rethrows -> [Value] {
        var values: [Value] = []
        for element in self {
            try await values.append(transform(element))
        }
        return values
    }

    /// Transforms each element concurrently, preserving original order.
    ///
    /// Uses structured concurrency via `TaskGroup` for proper cancellation propagation.
    ///
    /// Example:
    /// ```swift
    /// let users = await userIDs.concurrentMap { await fetchUser(id: $0) }
    /// ```
    ///
    /// - Parameters:
    ///   - maxNumberOfTasks: Maximum number of tasks running in parallel. `nil` means unlimited.
    ///   - priority: Task priority (default: inherits from parent)
    ///   - transform: Async transformation closure
    public func concurrentMap<Value: Sendable>(
        maxNumberOfTasks: Int? = nil,
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async -> Value
    ) async -> [Value] where Element: Sendable {
        await withTaskGroup(of: (Int, Value).self) { group in
            var results: [(Int, Value)] = []
            for (index, element) in enumerated() {
                if let max = maxNumberOfTasks, index >= max {
                    if let result = await group.next() {
                        results.append(result)
                    }
                }
                group.addTask(priority: priority) {
                    await (index, transform(element))
                }
            }
            for await result in group {
                results.append(result)
            }
            return results
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }
    }

    /// Transforms each element concurrently, preserving original order. Throws on first error.
    ///
    /// Uses structured concurrency via `ThrowingTaskGroup` for proper cancellation propagation.
    /// If any transformation throws, remaining tasks are cancelled automatically.
    ///
    /// Example:
    /// ```swift
    /// let data = try await urls.concurrentMap { try await URLSession.shared.data(from: $0).0 }
    /// ```
    ///
    /// - Parameters:
    ///   - maxNumberOfTasks: Maximum number of tasks running in parallel. `nil` means unlimited.
    ///   - priority: Task priority (default: inherits from parent)
    ///   - transform: Async throwing transformation closure
    public func concurrentMap<Value: Sendable>(
        maxNumberOfTasks: Int? = nil,
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> Value
    ) async throws -> [Value] where Element: Sendable {
        try await withThrowingTaskGroup(of: (Int, Value).self) { group in
            var results: [(Int, Value)] = []
            for (index, element) in enumerated() {
                if let max = maxNumberOfTasks, index >= max {
                    if let result = try await group.next() {
                        results.append(result)
                    }
                }
                group.addTask(priority: priority) {
                    try await (index, transform(element))
                }
            }
            for try await result in group {
                results.append(result)
            }
            return results
                .sorted { $0.0 < $1.0 }
                .map(\.1)
        }
    }
}
