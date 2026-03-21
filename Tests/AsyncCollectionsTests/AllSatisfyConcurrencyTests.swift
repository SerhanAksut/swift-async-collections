import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncAllSatisfy
@Test func asyncAllSatisfyReturnsTrueWhenAllMatch() async {
    let result = await [2, 4, 6].asyncAllSatisfy { $0.isMultiple(of: 2) }
    #expect(result == true)
}

@Test func asyncAllSatisfyReturnsFalseWhenOneFails() async {
    let result = await [2, 3, 4].asyncAllSatisfy { $0.isMultiple(of: 2) }
    #expect(result == false)
}

@Test func asyncAllSatisfyHandlesEmptySequence() async {
    let result = await [Int]().asyncAllSatisfy { $0 > 0 }
    #expect(result == true)
}

@Test func asyncAllSatisfyShortCircuits() async {
    let counter = Mutex(0)
    let result = await [1, 2, 3, 4, 5].asyncAllSatisfy { value in
        counter.withLock { $0 += 1 }
        return value < 3
    }
    #expect(result == false)
    let count = counter.withLock { $0 }
    #expect(count == 3)
}

@Test func asyncAllSatisfyWithAsyncPredicate() async throws {
    let result = try await [2, 4, 6].asyncAllSatisfy { value in
        try await Task.sleep(for: .milliseconds(10))
        return value.isMultiple(of: 2)
    }
    #expect(result == true)
}

// MARK: - concurrentAllSatisfy
@Test func concurrentAllSatisfyReturnsTrueWhenAllMatch() async {
    let result = await [2, 4, 6, 8, 10].concurrentAllSatisfy { $0.isMultiple(of: 2) }
    #expect(result == true)
}

@Test func concurrentAllSatisfyReturnsFalseWhenOneFails() async {
    let result = await [2, 4, 5, 8, 10].concurrentAllSatisfy { $0.isMultiple(of: 2) }
    #expect(result == false)
}

@Test func concurrentAllSatisfyHandlesEmptySequence() async {
    let result = await [Int]().concurrentAllSatisfy { $0 > 0 }
    #expect(result == true)
}

@Test func concurrentAllSatisfySingleElement() async {
    let match = await [2].concurrentAllSatisfy { $0.isMultiple(of: 2) }
    #expect(match == true)

    let noMatch = await [3].concurrentAllSatisfy { $0.isMultiple(of: 2) }
    #expect(noMatch == false)
}

@Test func concurrentAllSatisfyRespectsMaxTasks() async {
    let result = await [2, 4, 6, 8, 10].concurrentAllSatisfy(maxNumberOfTasks: 2) {
        $0.isMultiple(of: 2)
    }
    #expect(result == true)
}

@Test func concurrentAllSatisfyCancelsEarlyInBackpressureLoop() async {
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
@Test func concurrentAllSatisfyThrowingReturnsTrueWhenAllMatch() async throws {
    let result = try await [2, 4, 6].concurrentAllSatisfy { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value.isMultiple(of: 2)
    }
    #expect(result == true)
}

@Test func concurrentAllSatisfyThrowingReturnsFalseWhenOneFails() async throws {
    let result = try await [2, 3, 4].concurrentAllSatisfy { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value.isMultiple(of: 2)
    }
    #expect(result == false)
}

@Test func concurrentAllSatisfyThrowingRespectsMaxTasks() async throws {
    let result = try await [2, 4, 6, 8, 10].concurrentAllSatisfy(maxNumberOfTasks: 2) { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value.isMultiple(of: 2)
    }
    #expect(result == true)
}

@Test func concurrentAllSatisfyThrowingCancelsEarlyInBackpressureLoop() async throws {
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

@Test func concurrentAllSatisfyThrowingCancelsOnError() async {
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
