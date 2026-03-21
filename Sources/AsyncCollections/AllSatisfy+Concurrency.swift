
import Foundation

extension Sequence {
    /// Checks whether all elements satisfy an async predicate, sequentially.
    ///
    /// Elements are evaluated one at a time in order. Short-circuits on the first non-match.
    /// For parallel evaluation, use `concurrentAllSatisfy`.
    ///
    /// Example:
    /// ```swift
    /// let allEven = try await numbers.asyncAllSatisfy { try await checkIsEven($0) }
    /// ```
    public func asyncAllSatisfy(
        _ predicate: (Element) async throws -> Bool
    ) async rethrows -> Bool {
        for element in self {
            if try await !predicate(element) {
                return false
            }
        }
        return true
    }

    /// Checks whether all elements satisfy an async predicate, concurrently.
    ///
    /// Uses structured concurrency via `TaskGroup`. Short-circuits and cancels remaining
    /// tasks as soon as a non-matching element is found.
    ///
    /// Example:
    /// ```swift
    /// let allValid = await items.concurrentAllSatisfy { await validate($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - maxNumberOfTasks: Maximum number of tasks running in parallel. `nil` means unlimited.
    ///   - priority: Task priority (default: inherits from parent)
    ///   - predicate: Async predicate closure to evaluate each element
    public func concurrentAllSatisfy(
        maxNumberOfTasks: Int? = nil,
        priority: TaskPriority? = nil,
        _ predicate: @escaping @Sendable (Element) async -> Bool
    ) async -> Bool where Element: Sendable {
        await withTaskGroup(of: Bool.self) { group in
            for (index, element) in enumerated() {
                if let max = maxNumberOfTasks, index >= max {
                    if let result = await group.next(), !result {
                        group.cancelAll()
                        return false
                    }
                }
                group.addTask(priority: priority) {
                    await predicate(element)
                }
            }
            for await result in group {
                if !result {
                    group.cancelAll()
                    return false
                }
            }
            return true
        }
    }

    /// Checks whether all elements satisfy an async predicate, concurrently. Throws on first error.
    ///
    /// Uses structured concurrency via `ThrowingTaskGroup`. Short-circuits and cancels remaining
    /// tasks as soon as a non-matching element is found. If any predicate throws, remaining tasks
    /// are cancelled automatically.
    ///
    /// Example:
    /// ```swift
    /// let allValid = try await items.concurrentAllSatisfy { try await validate($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - maxNumberOfTasks: Maximum number of tasks running in parallel. `nil` means unlimited.
    ///   - priority: Task priority (default: inherits from parent)
    ///   - predicate: Async throwing predicate closure to evaluate each element
    public func concurrentAllSatisfy(
        maxNumberOfTasks: Int? = nil,
        priority: TaskPriority? = nil,
        _ predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async throws -> Bool where Element: Sendable {
        try await withThrowingTaskGroup(of: Bool.self) { group in
            for (index, element) in enumerated() {
                if let max = maxNumberOfTasks, index >= max {
                    if let result = try await group.next(), !result {
                        group.cancelAll()
                        return false
                    }
                }
                group.addTask(priority: priority) {
                    try await predicate(element)
                }
            }
            for try await result in group {
                if !result {
                    group.cancelAll()
                    return false
                }
            }
            return true
        }
    }
}
