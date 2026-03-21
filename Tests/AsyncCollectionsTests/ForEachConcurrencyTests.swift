import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncForEach
@Test("asyncForEach processes all elements")
func async_for_each_processes_all_elements() async {
    var collected = [Int]()
    await [1, 2, 3].asyncForEach { collected.append($0) }
    #expect(collected == [1, 2, 3])
}

// MARK: - concurrentForEach
@Test("concurrentForEach processes all elements")
func concurrent_for_each_processes_all_elements() async {
    let collected = Mutex([Int]())
    await [1, 2, 3, 4, 5].concurrentForEach { value in
        collected.withLock { $0.append(value) }
    }
    let result = collected.withLock { $0.sorted() }
    #expect(result == [1, 2, 3, 4, 5])
}

@Test("concurrentForEach respects max tasks")
func concurrent_for_each_respects_max_tasks() async {
    let collected = Mutex([Int]())
    await [1, 2, 3, 4, 5].concurrentForEach(maxNumberOfTasks: 2) { value in
        collected.withLock { $0.append(value) }
    }
    let result = collected.withLock { $0.sorted() }
    #expect(result == [1, 2, 3, 4, 5])
}

@Test("concurrentForEach handles empty sequence")
func concurrent_for_each_handles_empty_sequence() async {
    let collected = Mutex([Int]())
    await [Int]().concurrentForEach { value in
        collected.withLock { $0.append(value) }
    }
    let result = collected.withLock { $0 }
    #expect(result.isEmpty)
}

@Test("concurrentForEach handles single element")
func concurrent_for_each_handles_single_element() async {
    let collected = Mutex([Int]())
    await [42].concurrentForEach { value in
        collected.withLock { $0.append(value) }
    }
    let result = collected.withLock { $0 }
    #expect(result == [42])
}

// MARK: - concurrentForEach (throwing)
@Test("concurrentForEach throwing processes all elements")
func concurrent_for_each_throwing_processes_all_elements() async throws {
    let collected = Mutex([Int]())
    try await [1, 2, 3, 4, 5].concurrentForEach { value in
        try await Task.sleep(for: .milliseconds(1))
        collected.withLock { $0.append(value) }
    }
    let result = collected.withLock { $0.sorted() }
    #expect(result == [1, 2, 3, 4, 5])
}

@Test("concurrentForEach throwing respects max tasks")
func concurrent_for_each_throwing_respects_max_tasks() async throws {
    let collected = Mutex([Int]())
    try await [1, 2, 3, 4, 5].concurrentForEach(maxNumberOfTasks: 2) { value in
        try await Task.sleep(for: .milliseconds(1))
        collected.withLock { $0.append(value) }
    }
    let result = collected.withLock { $0.sorted() }
    #expect(result == [1, 2, 3, 4, 5])
}

@Test("concurrentForEach throwing propagates error")
func concurrent_for_each_throwing_propagates_error() async {
    struct TestError: Error {}

    do {
        try await [1, 2, 3].concurrentForEach { value in
            if value == 2 { throw TestError() }
        }
        Issue.record("Expected error to be thrown")
    } catch {
        #expect(error is TestError)
    }
}
