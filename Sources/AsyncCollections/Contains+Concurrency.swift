
import Foundation

extension Sequence {
    /// Checks whether any element satisfies an async predicate, sequentially.
    ///
    /// Elements are evaluated one at a time in order. Short-circuits on the first match.
    /// For parallel evaluation, use `concurrentContains`.
    ///
    /// Example:
    /// ```swift
    /// let hasAdmin = try await users.asyncContains { try await checkIsAdmin($0) }
    /// ```
    public func asyncContains(
        where predicate: (Element) async throws -> Bool
    ) async rethrows -> Bool {
        for element in self {
            if try await predicate(element) {
                return true
            }
        }
        return false
    }

    /// Checks whether any element satisfies an async predicate, concurrently.
    ///
    /// Uses structured concurrency via `TaskGroup`. Short-circuits and cancels remaining
    /// tasks as soon as a matching element is found.
    ///
    /// Example:
    /// ```swift
    /// let hasAdmin = await users.concurrentContains { await checkIsAdmin($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - maxNumberOfTasks: Maximum number of tasks running in parallel. `nil` means unlimited.
    ///   - priority: Task priority (default: inherits from parent)
    ///   - predicate: Async predicate closure to evaluate each element
    public func concurrentContains(
        maxNumberOfTasks: Int? = nil,
        priority: TaskPriority? = nil,
        where predicate: @escaping @Sendable (Element) async -> Bool
    ) async -> Bool where Element: Sendable {
        await withTaskGroup(of: Bool.self) { group in
            for (index, element) in enumerated() {
                if let max = maxNumberOfTasks, index >= max {
                    if let result = await group.next(), result {
                        group.cancelAll()
                        return true
                    }
                }
                group.addTask(priority: priority) {
                    await predicate(element)
                }
            }
            for await result in group {
                if result {
                    group.cancelAll()
                    return true
                }
            }
            return false
        }
    }

    /// Checks whether any element satisfies an async predicate, concurrently. Throws on first error.
    ///
    /// Uses structured concurrency via `ThrowingTaskGroup`. Short-circuits and cancels remaining
    /// tasks as soon as a matching element is found. If any predicate throws, remaining tasks
    /// are cancelled automatically.
    ///
    /// Example:
    /// ```swift
    /// let hasAdmin = try await users.concurrentContains { try await checkIsAdmin($0) }
    /// ```
    ///
    /// - Parameters:
    ///   - maxNumberOfTasks: Maximum number of tasks running in parallel. `nil` means unlimited.
    ///   - priority: Task priority (default: inherits from parent)
    ///   - predicate: Async throwing predicate closure to evaluate each element
    public func concurrentContains(
        maxNumberOfTasks: Int? = nil,
        priority: TaskPriority? = nil,
        where predicate: @escaping @Sendable (Element) async throws -> Bool
    ) async throws -> Bool where Element: Sendable {
        try await withThrowingTaskGroup(of: Bool.self) { group in
            for (index, element) in enumerated() {
                if let max = maxNumberOfTasks, index >= max {
                    if let result = try await group.next(), result {
                        group.cancelAll()
                        return true
                    }
                }
                group.addTask(priority: priority) {
                    try await predicate(element)
                }
            }
            for try await result in group {
                if result {
                    group.cancelAll()
                    return true
                }
            }
            return false
        }
    }
}
