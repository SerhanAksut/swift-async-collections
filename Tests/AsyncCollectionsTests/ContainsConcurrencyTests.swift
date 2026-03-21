import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncContains
@Test("asyncContains finds matching element")
func async_contains_finds_matching_element() async {
    let result = await [1, 2, 3, 4, 5].asyncContains { $0 == 3 }
    #expect(result == true)
}

@Test("asyncContains returns false when no match")
func async_contains_returns_false_when_no_match() async {
    let result = await [1, 2, 3, 4, 5].asyncContains { $0 == 99 }
    #expect(result == false)
}

@Test("asyncContains handles empty sequence")
func async_contains_handles_empty_sequence() async {
    let result = await [Int]().asyncContains { $0 > 0 }
    #expect(result == false)
}

@Test("asyncContains short-circuits")
func async_contains_short_circuits() async {
    let counter = Mutex(0)
    let result = await [1, 2, 3, 4, 5].asyncContains { value in
        counter.withLock { $0 += 1 }
        return value == 2
    }
    #expect(result == true)
    let count = counter.withLock { $0 }
    #expect(count == 2)
}

@Test("asyncContains with async predicate")
func async_contains_with_async_predicate() async throws {
    let result = try await [1, 2, 3, 4, 5].asyncContains { value in
        try await Task.sleep(for: .milliseconds(10))
        return value == 4
    }
    #expect(result == true)
}

// MARK: - concurrentContains
@Test("concurrentContains finds matching element")
func concurrent_contains_finds_matching_element() async {
    let result = await [1, 2, 3, 4, 5].concurrentContains { $0 == 3 }
    #expect(result == true)
}

@Test("concurrentContains returns false when no match")
func concurrent_contains_returns_false_when_no_match() async {
    let result = await [1, 2, 3, 4, 5].concurrentContains { $0 == 99 }
    #expect(result == false)
}

@Test("concurrentContains handles empty sequence")
func concurrent_contains_handles_empty_sequence() async {
    let result = await [Int]().concurrentContains { $0 > 0 }
    #expect(result == false)
}

@Test("concurrentContains handles single element")
func concurrent_contains_single_element() async {
    let found = await [42].concurrentContains { $0 == 42 }
    #expect(found == true)

    let notFound = await [42].concurrentContains { $0 == 99 }
    #expect(notFound == false)
}

@Test("concurrentContains respects max tasks")
func concurrent_contains_respects_max_tasks() async {
    let result = await [1, 2, 3, 4, 5].concurrentContains(maxNumberOfTasks: 2) {
        $0 == 4
    }
    #expect(result == true)
}

@Test("concurrentContains respects max tasks with no match")
func concurrent_contains_respects_max_tasks_no_match() async {
    let result = await [1, 2, 3, 4, 5].concurrentContains(maxNumberOfTasks: 2) {
        $0 == 99
    }
    #expect(result == false)
}

@Test("concurrentContains cancels early in backpressure loop")
func concurrent_contains_cancels_early_in_backpressure_loop() async {
    let evaluatedCount = Mutex(0)
    let result = await [1, 2, 3, 4, 5].concurrentContains(maxNumberOfTasks: 2) { value in
        evaluatedCount.withLock { $0 += 1 }
        try? await Task.sleep(for: .milliseconds(10))
        return value == 2
    }
    #expect(result == true)
    let count = evaluatedCount.withLock { $0 }
    #expect(count <= 3)
}

// MARK: - concurrentContains (throwing)
@Test("concurrentContains throwing finds matching element")
func concurrent_contains_throwing_finds_matching_element() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentContains { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 3
    }
    #expect(result == true)
}

@Test("concurrentContains throwing returns false when no match")
func concurrent_contains_throwing_returns_false_when_no_match() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentContains { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 99
    }
    #expect(result == false)
}

@Test("concurrentContains throwing respects max tasks")
func concurrent_contains_throwing_respects_max_tasks() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentContains(maxNumberOfTasks: 2) { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 4
    }
    #expect(result == true)
}

@Test("concurrentContains throwing cancels early in backpressure loop")
func concurrent_contains_throwing_cancels_early_in_backpressure_loop() async throws {
    let evaluatedCount = Mutex(0)
    let result = try await [1, 2, 3, 4, 5].concurrentContains(maxNumberOfTasks: 2) { value -> Bool in
        evaluatedCount.withLock { $0 += 1 }
        try await Task.sleep(for: .milliseconds(10))
        return value == 2
    }
    #expect(result == true)
    let count = evaluatedCount.withLock { $0 }
    #expect(count <= 3)
}

@Test("concurrentContains throwing cancels on error")
func concurrent_contains_throwing_cancels_on_error() async {
    struct TestError: Error {}

    do {
        _ = try await [1, 2, 3].concurrentContains { value -> Bool in
            if value == 2 { throw TestError() }
            return false
        }
        Issue.record("Expected error to be thrown")
    } catch {
        #expect(error is TestError)
    }
}
