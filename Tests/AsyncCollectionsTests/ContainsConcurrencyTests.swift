import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncContains
@Test func asyncContainsFindsMatchingElement() async {
    let result = await [1, 2, 3, 4, 5].asyncContains { $0 == 3 }
    #expect(result == true)
}

@Test func asyncContainsReturnsFalseWhenNoMatch() async {
    let result = await [1, 2, 3, 4, 5].asyncContains { $0 == 99 }
    #expect(result == false)
}

@Test func asyncContainsHandlesEmptySequence() async {
    let result = await [Int]().asyncContains { $0 > 0 }
    #expect(result == false)
}

@Test func asyncContainsShortCircuits() async {
    let counter = Mutex(0)
    let result = await [1, 2, 3, 4, 5].asyncContains { value in
        counter.withLock { $0 += 1 }
        return value == 2
    }
    #expect(result == true)
    let count = counter.withLock { $0 }
    #expect(count == 2)
}

@Test func asyncContainsWithAsyncPredicate() async throws {
    let result = try await [1, 2, 3, 4, 5].asyncContains { value in
        try await Task.sleep(for: .milliseconds(10))
        return value == 4
    }
    #expect(result == true)
}

// MARK: - concurrentContains
@Test func concurrentContainsFindsMatchingElement() async {
    let result = await [1, 2, 3, 4, 5].concurrentContains { $0 == 3 }
    #expect(result == true)
}

@Test func concurrentContainsReturnsFalseWhenNoMatch() async {
    let result = await [1, 2, 3, 4, 5].concurrentContains { $0 == 99 }
    #expect(result == false)
}

@Test func concurrentContainsHandlesEmptySequence() async {
    let result = await [Int]().concurrentContains { $0 > 0 }
    #expect(result == false)
}

@Test func concurrentContainsSingleElement() async {
    let found = await [42].concurrentContains { $0 == 42 }
    #expect(found == true)

    let notFound = await [42].concurrentContains { $0 == 99 }
    #expect(notFound == false)
}

@Test func concurrentContainsRespectsMaxTasks() async {
    let result = await [1, 2, 3, 4, 5].concurrentContains(maxNumberOfTasks: 2) {
        $0 == 4
    }
    #expect(result == true)
}

@Test func concurrentContainsRespectsMaxTasksNoMatch() async {
    let result = await [1, 2, 3, 4, 5].concurrentContains(maxNumberOfTasks: 2) {
        $0 == 99
    }
    #expect(result == false)
}

@Test func concurrentContainsCancelsEarlyInBackpressureLoop() async {
    // With maxNumberOfTasks: 2, after enqueueing indices 0 and 1,
    // the loop awaits group.next() before enqueueing index 2.
    // Element 1 matches, so group.next() returns true inside the
    // backpressure block, triggering cancelAll() and early return.
    let evaluatedCount = Mutex(0)
    let result = await [1, 2, 3, 4, 5].concurrentContains(maxNumberOfTasks: 2) { value in
        evaluatedCount.withLock { $0 += 1 }
        try? await Task.sleep(for: .milliseconds(10))
        return value == 2
    }
    #expect(result == true)
    let count = evaluatedCount.withLock { $0 }
    // Only elements 1 and 2 should be enqueued (maxNumberOfTasks: 2).
    // Element 2 matches, so the loop cancels before enqueueing 3, 4, 5.
    #expect(count <= 3)
}

// MARK: - concurrentContains (throwing)
@Test func concurrentContainsThrowingFindsMatchingElement() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentContains { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 3
    }
    #expect(result == true)
}

@Test func concurrentContainsThrowingReturnsFalseWhenNoMatch() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentContains { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 99
    }
    #expect(result == false)
}

@Test func concurrentContainsThrowingRespectsMaxTasks() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentContains(maxNumberOfTasks: 2) { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 4
    }
    #expect(result == true)
}

@Test func concurrentContainsThrowingCancelsEarlyInBackpressureLoop() async throws {
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

@Test func concurrentContainsThrowingCancelsOnError() async {
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
