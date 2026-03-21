import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncFirst
@Test func asyncFirstFindsMatchingElement() async {
    let result = await [1, 2, 3, 4, 5].asyncFirst { $0 == 3 }
    #expect(result == 3)
}

@Test func asyncFirstReturnsNilWhenNoMatch() async {
    let result = await [1, 2, 3, 4, 5].asyncFirst { $0 == 99 }
    #expect(result == nil)
}

@Test func asyncFirstHandlesEmptySequence() async {
    let result = await [Int]().asyncFirst { $0 > 0 }
    #expect(result == nil)
}

@Test func asyncFirstSingleElement() async {
    let found = await [42].asyncFirst { $0 == 42 }
    #expect(found == 42)

    let notFound = await [42].asyncFirst { $0 == 99 }
    #expect(notFound == nil)
}

@Test func asyncFirstShortCircuits() async {
    let counter = Mutex(0)
    let result = await [1, 2, 3, 4, 5].asyncFirst { value in
        counter.withLock { $0 += 1 }
        return value == 2
    }
    #expect(result == 2)
    let count = counter.withLock { $0 }
    #expect(count == 2)
}

@Test func asyncFirstReturnsFirstMatch() async {
    let counter = Mutex(0)
    let result = await [1, 2, 3, 2, 1].asyncFirst { value in
        counter.withLock { $0 += 1 }
        return value == 2
    }
    #expect(result == 2)
    let count = counter.withLock { $0 }
    #expect(count == 2)
}

@Test func asyncFirstWithAsyncPredicate() async throws {
    let result = try await [1, 2, 3, 4, 5].asyncFirst { value in
        try await Task.sleep(for: .milliseconds(10))
        return value == 4
    }
    #expect(result == 4)
}

// MARK: - concurrentFirst
@Test func concurrentFirstFindsMatchingElement() async {
    let result = await [1, 2, 3, 4, 5].concurrentFirst { $0 == 3 }
    #expect(result == 3)
}

@Test func concurrentFirstReturnsNilWhenNoMatch() async {
    let result = await [1, 2, 3, 4, 5].concurrentFirst { $0 == 99 }
    #expect(result == nil)
}

@Test func concurrentFirstHandlesEmptySequence() async {
    let result = await [Int]().concurrentFirst { $0 > 0 }
    #expect(result == nil)
}

@Test func concurrentFirstSingleElement() async {
    let found = await [42].concurrentFirst { $0 == 42 }
    #expect(found == 42)

    let notFound = await [42].concurrentFirst { $0 == 99 }
    #expect(notFound == nil)
}

@Test func concurrentFirstReturnsFirstMatchWhenAllMatch() async {
    // All elements satisfy predicate; must return element at index 0.
    let result = await [10, 20, 30].concurrentFirst { $0 > 0 }
    #expect(result == 10)
}

@Test func concurrentFirstReturnsLastElementWhenOnlyMatch() async {
    let result = await [1, 2, 3, 4, 5].concurrentFirst { $0 == 5 }
    #expect(result == 5)
}

@Test func concurrentFirstRespectsMaxTasks() async {
    let result = await [1, 2, 3, 4, 5].concurrentFirst(maxNumberOfTasks: 2) {
        $0 == 4
    }
    #expect(result == 4)
}

@Test func concurrentFirstRespectsMaxTasksNoMatch() async {
    let result = await [1, 2, 3, 4, 5].concurrentFirst(maxNumberOfTasks: 2) {
        $0 == 99
    }
    #expect(result == nil)
}

@Test func concurrentFirstPreservesOrder() async {
    let result = await [3, 1, 2].concurrentFirst { value -> Bool in
        try? await Task.sleep(for: .milliseconds(value * 10))
        return value < 3
    }
    #expect(result == 1)
}

@Test func concurrentFirstPreservesOrderWithMultipleMatches() async {
    let result = await [5, 1, 3, 4].concurrentFirst { value -> Bool in
        try? await Task.sleep(for: .milliseconds(value * 10))
        return value > 2
    }
    #expect(result == 5)
}

@Test func concurrentFirstCancelsEarlyWhenFirstElementMatches() async {
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

@Test func concurrentFirstCancelsEarlyInBackpressureLoopWithCompletedLowerIndices() async {
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

@Test func concurrentFirstUpdatesMatchToLowerIndexInBackpressureLoop() async {
    let result = await [100, 30, 5, 80, 90].concurrentFirst(maxNumberOfTasks: 3) { value -> Bool in
        try? await Task.sleep(for: .milliseconds(value))
        return value < 50
    }
    #expect(result == 30)
}

@Test func concurrentFirstCancelsEarlyInDrainLoop() async {
    let result = await [1, 2, 3, 4, 5].concurrentFirst { value in
        try? await Task.sleep(for: .milliseconds(10))
        return value == 1
    }
    #expect(result == 1)
}

@Test func concurrentFirstUpdatesMatchToLowerIndexInDrainLoop() async {
    let result = await [50, 40, 10, 30].concurrentFirst { value -> Bool in
        try? await Task.sleep(for: .milliseconds(value))
        return value < 45
    }
    #expect(result == 40)
}

// MARK: - concurrentFirst (throwing)
@Test func concurrentFirstThrowingFindsMatchingElement() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentFirst { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 3
    }
    #expect(result == 3)
}

@Test func concurrentFirstThrowingReturnsNilWhenNoMatch() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentFirst { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 99
    }
    #expect(result == nil)
}

@Test func concurrentFirstThrowingHandlesEmptySequence() async throws {
    let result = try await [Int]().concurrentFirst { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value > 0
    }
    #expect(result == nil)
}

@Test func concurrentFirstThrowingSingleElement() async throws {
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

@Test func concurrentFirstThrowingRespectsMaxTasks() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentFirst(maxNumberOfTasks: 2) { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 4
    }
    #expect(result == 4)
}

@Test func concurrentFirstThrowingRespectsMaxTasksNoMatch() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentFirst(maxNumberOfTasks: 2) { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value == 99
    }
    #expect(result == nil)
}

@Test func concurrentFirstThrowingPreservesOrder() async throws {
    let result = try await [3, 1, 2].concurrentFirst { value -> Bool in
        try await Task.sleep(for: .milliseconds(value * 10))
        return value < 3
    }
    #expect(result == 1)
}

@Test func concurrentFirstThrowingCancelsEarlyWhenFirstElementMatches() async throws {
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

@Test func concurrentFirstThrowingCancelsEarlyInBackpressureLoopWithCompletedLowerIndices() async throws {
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

@Test func concurrentFirstThrowingUpdatesMatchToLowerIndexInBackpressureLoop() async throws {
    let result = try await [100, 30, 5, 80, 90].concurrentFirst(maxNumberOfTasks: 3) { value -> Bool in
        try await Task.sleep(for: .milliseconds(value))
        return value < 50
    }
    #expect(result == 30)
}

@Test func concurrentFirstThrowingUpdatesMatchToLowerIndexInDrainLoop() async throws {
    let result = try await [50, 40, 10, 30].concurrentFirst { value -> Bool in
        try await Task.sleep(for: .milliseconds(value))
        return value < 45
    }
    #expect(result == 40)
}

@Test func concurrentFirstThrowingCancelsOnError() async {
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
