import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncFirst
@Test("asyncFirst finds matching element")
func async_first_finds_matching_element() async {
    let result = await [1, 2, 3, 4, 5].asyncFirst { $0 == 3 }
    #expect(result == 3)
}

@Test("asyncFirst returns nil when no match")
func async_first_returns_nil_when_no_match() async {
    let result = await [1, 2, 3, 4, 5].asyncFirst { $0 == 99 }
    #expect(result == nil)
}

@Test("asyncFirst handles empty sequence")
func async_first_handles_empty_sequence() async {
    let result = await [Int]().asyncFirst { $0 > 0 }
    #expect(result == nil)
}

@Test("asyncFirst handles single element")
func async_first_single_element() async {
    let found = await [42].asyncFirst { $0 == 42 }
    #expect(found == 42)

    let notFound = await [42].asyncFirst { $0 == 99 }
    #expect(notFound == nil)
}

@Test("asyncFirst short-circuits")
func async_first_short_circuits() async {
    let counter = Mutex(0)
    let result = await [1, 2, 3, 4, 5].asyncFirst { value in
        counter.withLock { $0 += 1 }
        return value == 2
    }
    #expect(result == 2)
    let count = counter.withLock { $0 }
    #expect(count == 2)
}

@Test("asyncFirst returns first match among duplicates")
func async_first_returns_first_match() async {
    let counter = Mutex(0)
    let result = await [1, 2, 3, 2, 1].asyncFirst { value in
        counter.withLock { $0 += 1 }
        return value == 2
    }
    #expect(result == 2)
    let count = counter.withLock { $0 }
    #expect(count == 2)
}

@Test("asyncFirst with async predicate")
func async_first_with_async_predicate() async throws {
    let result = try await [1, 2, 3, 4, 5].asyncFirst { value in
        try await Task.sleep(for: .milliseconds(10))
        return value == 4
    }
    #expect(result == 4)
}

// MARK: - concurrentFirst
@Test("concurrentFirst finds matching element")
func concurrent_first_finds_matching_element() async {
    let result = await [1, 2, 3, 4, 5].concurrentFirst { $0 == 3 }
    #expect(result == 3)
}

@Test("concurrentFirst returns nil when no match")
func concurrent_first_returns_nil_when_no_match() async {
    let result = await [1, 2, 3, 4, 5].concurrentFirst { $0 == 99 }
    #expect(result == nil)
}

@Test("concurrentFirst handles empty sequence")
func concurrent_first_handles_empty_sequence() async {
    let result = await [Int]().concurrentFirst { $0 > 0 }
    #expect(result == nil)
}

@Test("concurrentFirst handles single element")
func concurrent_first_single_element() async {
    let found = await [42].concurrentFirst { $0 == 42 }
    #expect(found == 42)

    let notFound = await [42].concurrentFirst { $0 == 99 }
    #expect(notFound == nil)
}

@Test("concurrentFirst returns first match when all match")
func concurrent_first_returns_first_match_when_all_match() async {
    let result = await [10, 20, 30].concurrentFirst { $0 > 0 }
    #expect(result == 10)
}

@Test("concurrentFirst returns last element when only match")
func concurrent_first_returns_last_element_when_only_match() async {
    let result = await [1, 2, 3, 4, 5].concurrentFirst { $0 == 5 }
    #expect(result == 5)
}

@Test("concurrentFirst respects max tasks")
func concurrent_first_respects_max_tasks() async {
    let result = await [1, 2, 3, 4, 5].concurrentFirst(maxNumberOfTasks: 2) {
        $0 == 4
    }
    #expect(result == 4)
}

@Test("concurrentFirst respects max tasks with no match")
func concurrent_first_respects_max_tasks_no_match() async {
    let result = await [1, 2, 3, 4, 5].concurrentFirst(maxNumberOfTasks: 2) {
        $0 == 99
    }
    #expect(result == nil)
}

@Test("concurrentFirst preserves order")
func concurrent_first_preserves_order() async {
    let result = await [3, 1, 2].concurrentFirst { value -> Bool in
        try? await Task.sleep(for: .milliseconds(value * 10))
        return value < 3
    }
    #expect(result == 1)
}

@Test("concurrentFirst preserves order with multiple matches")
func concurrent_first_preserves_order_with_multiple_matches() async {
    let result = await [5, 1, 3, 4].concurrentFirst { value -> Bool in
        try? await Task.sleep(for: .milliseconds(value * 10))
        return value > 2
    }
    #expect(result == 5)
}

@Test("concurrentFirst cancels early when first element matches")
func concurrent_first_cancels_early_when_first_element_matches() async {
    let evaluatedCount = Mutex(0)
    let result = await [1, 2, 3, 4, 5].concurrentFirst(maxNumberOfTasks: 2) { value in
        evaluatedCount.withLock { $0 += 1 }
        try? await Task.sleep(for: .milliseconds(10))
        return value == 1
    }
    #expect(result == 1)
    let count = evaluatedCount.withLock { $0 }
    #expect(count <= 3)
}

@Test("concurrentFirst cancels early in backpressure loop with completed lower indices")
func concurrent_first_cancels_early_in_backpressure_loop_with_completed_lower_indices() async {
    let evaluatedCount = Mutex(0)
    let result = await [99, 42, 7, 8, 9].concurrentFirst(maxNumberOfTasks: 2) { value in
        evaluatedCount.withLock { $0 += 1 }
        try? await Task.sleep(for: .milliseconds(value == 99 ? 5 : 15))
        return value == 42
    }
    #expect(result == 42)
    let count = evaluatedCount.withLock { $0 }
    #expect(count <= 3)
}

@Test("concurrentFirst updates match to lower index in backpressure loop")
func concurrent_first_updates_match_to_lower_index_in_backpressure_loop() async {
    let result = await [100, 30, 5, 80, 90].concurrentFirst(maxNumberOfTasks: 3) { value -> Bool in
        try? await Task.sleep(for: .milliseconds(value))
        return value < 50
    }
    #expect(result == 30)
}

@Test("concurrentFirst cancels early in drain loop")
func concurrent_first_cancels_early_in_drain_loop() async {
    let result = await [1, 2, 3, 4, 5].concurrentFirst { value in
        try? await Task.sleep(for: .milliseconds(10))
        return value == 1
    }
    #expect(result == 1)
}

@Test("concurrentFirst updates match to lower index in drain loop")
func concurrent_first_updates_match_to_lower_index_in_drain_loop() async {
    let result = await [50, 40, 10, 30].concurrentFirst { value -> Bool in
        try? await Task.sleep(for: .milliseconds(value))
        return value < 45
    }
    #expect(result == 40)
}

// MARK: - concurrentFirst (throwing)
@Test("concurrentFirst throwing finds matching element")
func concurrent_first_throwing_finds_matching_element() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentFirst { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 3
    }
    #expect(result == 3)
}

@Test("concurrentFirst throwing returns nil when no match")
func concurrent_first_throwing_returns_nil_when_no_match() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentFirst { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 99
    }
    #expect(result == nil)
}

@Test("concurrentFirst throwing handles empty sequence")
func concurrent_first_throwing_handles_empty_sequence() async throws {
    let result = try await [Int]().concurrentFirst { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value > 0
    }
    #expect(result == nil)
}

@Test("concurrentFirst throwing handles single element")
func concurrent_first_throwing_single_element() async throws {
    let found = try await [42].concurrentFirst { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 42
    }
    #expect(found == 42)

    let notFound = try await [42].concurrentFirst { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 99
    }
    #expect(notFound == nil)
}

@Test("concurrentFirst throwing respects max tasks")
func concurrent_first_throwing_respects_max_tasks() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentFirst(maxNumberOfTasks: 2) { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 4
    }
    #expect(result == 4)
}

@Test("concurrentFirst throwing respects max tasks with no match")
func concurrent_first_throwing_respects_max_tasks_no_match() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentFirst(maxNumberOfTasks: 2) { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 99
    }
    #expect(result == nil)
}

@Test("concurrentFirst throwing preserves order")
func concurrent_first_throwing_preserves_order() async throws {
    let result = try await [3, 1, 2].concurrentFirst { value -> Bool in
        try await Task.sleep(for: .milliseconds(value * 10))
        return value < 3
    }
    #expect(result == 1)
}

@Test("concurrentFirst throwing cancels early when first element matches")
func concurrent_first_throwing_cancels_early_when_first_element_matches() async throws {
    let evaluatedCount = Mutex(0)
    let result = try await [1, 2, 3, 4, 5].concurrentFirst(maxNumberOfTasks: 2) { value -> Bool in
        evaluatedCount.withLock { $0 += 1 }
        try await Task.sleep(for: .milliseconds(10))
        return value == 1
    }
    #expect(result == 1)
    let count = evaluatedCount.withLock { $0 }
    #expect(count <= 3)
}

@Test("concurrentFirst throwing cancels early in backpressure loop with completed lower indices")
func concurrent_first_throwing_cancels_early_in_backpressure_loop_with_completed_lower_indices() async throws {
    let evaluatedCount = Mutex(0)
    let result = try await [99, 42, 7, 8, 9].concurrentFirst(maxNumberOfTasks: 2) { value -> Bool in
        evaluatedCount.withLock { $0 += 1 }
        try await Task.sleep(for: .milliseconds(value == 99 ? 5 : 15))
        return value == 42
    }
    #expect(result == 42)
    let count = evaluatedCount.withLock { $0 }
    #expect(count <= 3)
}

@Test("concurrentFirst throwing updates match to lower index in backpressure loop")
func concurrent_first_throwing_updates_match_to_lower_index_in_backpressure_loop() async throws {
    let result = try await [100, 30, 5, 80, 90].concurrentFirst(maxNumberOfTasks: 3) { value -> Bool in
        try await Task.sleep(for: .milliseconds(value))
        return value < 50
    }
    #expect(result == 30)
}

@Test("concurrentFirst throwing updates match to lower index in drain loop")
func concurrent_first_throwing_updates_match_to_lower_index_in_drain_loop() async throws {
    let result = try await [50, 40, 10, 30].concurrentFirst { value -> Bool in
        try await Task.sleep(for: .milliseconds(value))
        return value < 45
    }
    #expect(result == 40)
}

@Test("concurrentFirst throwing cancels on error")
func concurrent_first_throwing_cancels_on_error() async {
    struct TestError: Error {}

    do {
        _ = try await [1, 2, 3].concurrentFirst { value -> Bool in
            if value == 2 { throw TestError() }
            return false
        }
        Issue.record("Expected error to be thrown")
    } catch {
        #expect(error is TestError)
    }
}
