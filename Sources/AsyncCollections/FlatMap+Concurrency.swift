
import Foundation

extension Sequence {
    /// Transforms each element sequentially into a sequence and flattens the results.
    ///
    /// Elements are processed one at a time in order. For parallel processing, use `concurrentFlatMap`.
    ///
    /// Example:
    /// ```swift
    /// let allPosts = try await users.asyncFlatMap { try await fetchPosts(for: $0) }
    /// ```
    public func asyncFlatMap<Value: Sequence>(
        _ transform: (Element) async throws -> Value
    ) async rethrows -> [Value.Element] {
        var elements: [Value.Element] = []
        for element in self {
            try await elements.append(contentsOf: transform(element))
        }
        return elements
    }

    /// Transforms each element concurrently into a sequence and flattens the results.
    ///
    /// Uses structured concurrency via `TaskGroup` for proper cancellation propagation.
    ///
    /// Example:
    /// ```swift
    /// let allPosts = await users.concurrentFlatMap { await fetchPosts(for: $0) }
    /// ```
    ///
    /// - Parameters:
    ///   - maxNumberOfTasks: Maximum number of tasks running in parallel. `nil` means unlimited.
    ///   - priority: Task priority (default: inherits from parent)
    ///   - transform: Async transformation closure returning a sequence
    public func concurrentFlatMap<Value: Sequence & Sendable>(
        maxNumberOfTasks: Int? = nil,
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async -> Value
    ) async -> [Value.Element] where Element: Sendable {
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
                .flatMap(\.1)
        }
    }

    /// Transforms each element concurrently into a sequence and flattens the results. Throws on first error.
    ///
    /// Uses structured concurrency via `ThrowingTaskGroup` for proper cancellation propagation.
    /// If any transformation throws, remaining tasks are cancelled automatically.
    ///
    /// Example:
    /// ```swift
    /// let allPosts = try await users.concurrentFlatMap { try await fetchPosts(for: $0) }
    /// ```
    ///
    /// - Parameters:
    ///   - maxNumberOfTasks: Maximum number of tasks running in parallel. `nil` means unlimited.
    ///   - priority: Task priority (default: inherits from parent)
    ///   - transform: Async throwing transformation closure returning a sequence
    public func concurrentFlatMap<Value: Sequence & Sendable>(
        maxNumberOfTasks: Int? = nil,
        priority: TaskPriority? = nil,
        _ transform: @escaping @Sendable (Element) async throws -> Value
    ) async throws -> [Value.Element] where Element: Sendable {
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
                .flatMap(\.1)
        }
    }
}
