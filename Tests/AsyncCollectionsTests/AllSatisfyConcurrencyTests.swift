import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncAllSatisfy
@Test("asyncAllSatisfy returns true when all match")
func async_all_satisfy_returns_true_when_all_match() async {
    let result = await [2, 4, 6].asyncAllSatisfy { $0.isMultiple(of: 2) }
    #expect(result == true)
}

@Test("asyncAllSatisfy returns false when one fails")
func async_all_satisfy_returns_false_when_one_fails() async {
    let result = await [2, 3, 4].asyncAllSatisfy { $0.isMultiple(of: 2) }
    #expect(result == false)
}

@Test("asyncAllSatisfy handles empty sequence")
func async_all_satisfy_handles_empty_sequence() async {
    let result = await [Int]().asyncAllSatisfy { $0 > 0 }
    #expect(result == true)
}

@Test("asyncAllSatisfy short-circuits")
func async_all_satisfy_short_circuits() async {
    let counter = Mutex(0)
    let result = await [1, 2, 3, 4, 5].asyncAllSatisfy { value in
        counter.withLock { $0 += 1 }
        return value < 3
    }
    #expect(result == false)
    let count = counter.withLock { $0 }
    #expect(count == 3)
}

@Test("asyncAllSatisfy with async predicate")
func async_all_satisfy_with_async_predicate() async throws {
    let result = try await [2, 4, 6].asyncAllSatisfy { value in
        try await Task.sleep(for: .milliseconds(10))
        return value.isMultiple(of: 2)
    }
    #expect(result == true)
}

// MARK: - concurrentAllSatisfy
@Test("concurrentAllSatisfy returns true when all match")
func concurrent_all_satisfy_returns_true_when_all_match() async {
    let result = await [2, 4, 6, 8, 10].concurrentAllSatisfy { $0.isMultiple(of: 2) }
    #expect(result == true)
}

@Test("concurrentAllSatisfy returns false when one fails")
func concurrent_all_satisfy_returns_false_when_one_fails() async {
    let result = await [2, 4, 5, 8, 10].concurrentAllSatisfy { $0.isMultiple(of: 2) }
    #expect(result == false)
}

@Test("concurrentAllSatisfy handles empty sequence")
func concurrent_all_satisfy_handles_empty_sequence() async {
    let result = await [Int]().concurrentAllSatisfy { $0 > 0 }
    #expect(result == true)
}

@Test("concurrentAllSatisfy handles single element")
func concurrent_all_satisfy_single_element() async {
    let match = await [2].concurrentAllSatisfy { $0.isMultiple(of: 2) }
    #expect(match == true)

    let noMatch = await [3].concurrentAllSatisfy { $0.isMultiple(of: 2) }
    #expect(noMatch == false)
}

@Test("concurrentAllSatisfy respects max tasks")
func concurrent_all_satisfy_respects_max_tasks() async {
    let result = await [2, 4, 6, 8, 10].concurrentAllSatisfy(maxNumberOfTasks: 2) {
        $0.isMultiple(of: 2)
    }
    #expect(result == true)
}

@Test("concurrentAllSatisfy cancels early in backpressure loop")
func concurrent_all_satisfy_cancels_early_in_backpressure_loop() async {
    let evaluatedCount = Mutex(0)
    let result = await [2, 5, 3, 8, 10].concurrentAllSatisfy(maxNumberOfTasks: 2) { value in
        evaluatedCount.withLock { $0 += 1 }
        try? await Task.sleep(for: .milliseconds(10))
        return value.isMultiple(of: 2)
    }
    #expect(result == false)
    let count = evaluatedCount.withLock { $0 }
    #expect(count <= 3)
}

// MARK: - concurrentAllSatisfy (throwing)
@Test("concurrentAllSatisfy throwing returns true when all match")
func concurrent_all_satisfy_throwing_returns_true_when_all_match() async throws {
    let result = try await [2, 4, 6].concurrentAllSatisfy { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value.isMultiple(of: 2)
    }
    #expect(result == true)
}

@Test("concurrentAllSatisfy throwing returns false when one fails")
func concurrent_all_satisfy_throwing_returns_false_when_one_fails() async throws {
    let result = try await [2, 3, 4].concurrentAllSatisfy { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value.isMultiple(of: 2)
    }
    #expect(result == false)
}

@Test("concurrentAllSatisfy throwing respects max tasks")
func concurrent_all_satisfy_throwing_respects_max_tasks() async throws {
    let result = try await [2, 4, 6, 8, 10].concurrentAllSatisfy(maxNumberOfTasks: 2) { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value.isMultiple(of: 2)
    }
    #expect(result == true)
}

@Test("concurrentAllSatisfy throwing cancels early in backpressure loop")
func concurrent_all_satisfy_throwing_cancels_early_in_backpressure_loop() async throws {
    let evaluatedCount = Mutex(0)
    let result = try await [2, 5, 3, 8, 10].concurrentAllSatisfy(maxNumberOfTasks: 2) { value -> Bool in
        evaluatedCount.withLock { $0 += 1 }
        try await Task.sleep(for: .milliseconds(10))
        return value.isMultiple(of: 2)
    }
    #expect(result == false)
    let count = evaluatedCount.withLock { $0 }
    #expect(count <= 3)
}

@Test("concurrentAllSatisfy throwing cancels on error")
func concurrent_all_satisfy_throwing_cancels_on_error() async {
    struct TestError: Error {}

    do {
        _ = try await [1, 2, 3].concurrentAllSatisfy { value -> Bool in
            if value == 2 { throw TestError() }
            return true
        }
        Issue.record("Expected error to be thrown")
    } catch {
        #expect(error is TestError)
    }
}
