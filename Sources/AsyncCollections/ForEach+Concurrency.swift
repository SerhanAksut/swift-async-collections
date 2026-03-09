
import Foundation

extension Sequence {
    /// Performs an async operation on each element sequentially.
    ///
    /// Elements are processed one at a time in order. For parallel processing, use `concurrentForEach`.
    ///
    /// Example:
    /// ```swift
    /// try await users.asyncForEach { try await updateDatabase(with: $0) }
    /// ```
    public func asyncForEach(
        _ operation: (Element) async throws -> Void
    ) async rethrows {
        for element in self {
            try await operation(element)
        }
    }

    /// Performs an async operation on each element concurrently using structured concurrency.
    ///
    /// Creates one task per element within a task group. Waits for all operations to complete.
    ///
    /// Example:
    /// ```swift
    /// await users.concurrentForEach { await sendNotification(to: $0) }
    /// ```
    ///
    /// - Parameters:
    ///   - maxNumberOfTasks: Maximum number of tasks running in parallel. `nil` means unlimited.
    ///   - priority: Task priority (default: inherits from parent)
    ///   - operation: Async operation to perform on each element
    public func concurrentForEach(
        maxNumberOfTasks: Int? = nil,
        priority: TaskPriority? = nil,
        _ operation: @escaping @Sendable (Element) async -> Void
    ) async where Element: Sendable {
        await withTaskGroup(of: Void.self) { group in
            for (index, element) in enumerated() {
                if let max = maxNumberOfTasks, index >= max {
                    await group.next()
                }
                group.addTask(priority: priority) {
                    await operation(element)
                }
            }
        }
    }

    /// Performs an async operation on each element concurrently using structured concurrency. Throws on first error.
    ///
    /// Creates one task per element within a task group. Waits for all operations to complete.
    /// If any operation throws, remaining tasks are cancelled automatically.
    ///
    /// Example:
    /// ```swift
    /// try await users.concurrentForEach { try await updateDatabase(with: $0) }
    /// ```
    ///
    /// - Parameters:
    ///   - maxNumberOfTasks: Maximum number of tasks running in parallel. `nil` means unlimited.
    ///   - priority: Task priority (default: inherits from parent)
    ///   - operation: Async throwing operation to perform on each element
    public func concurrentForEach(
        maxNumberOfTasks: Int? = nil,
        priority: TaskPriority? = nil,
        _ operation: @escaping @Sendable (Element) async throws -> Void
    ) async throws where Element: Sendable {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for (index, element) in enumerated() {
                if let max = maxNumberOfTasks, index >= max {
                    try await group.next()
                }
                group.addTask(priority: priority) {
                    try await operation(element)
                }
            }
            // Drain remaining tasks to surface any thrown errors.
            // Without this loop, child task errors would be silently discarded since ThrowingTaskGroup only rethrows when iterated.
            for try await _ in group {}
        }
    }
}
