import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncMap
@Test func asyncMapTransformsElements() async {
    let result = await [1, 2, 3].asyncMap { $0 * 2 }
    #expect(result == [2, 4, 6])
}

@Test func asyncMapPreservesOrder() async throws {
    let result = try await [1, 2, 3].asyncMap { value -> String in
        try await Task.sleep(for: .milliseconds(10))
        return "\(value)"
    }
    #expect(result == ["1", "2", "3"])
}

@Test func asyncMapHandlesEmptySequence() async {
    let result = await [Int]().asyncMap { $0 * 2 }
    #expect(result.isEmpty)
}

// MARK: - concurrentMap
@Test func concurrentMapTransformsElements() async {
    let result = await [1, 2, 3].concurrentMap { $0 * 2 }
    #expect(result == [2, 4, 6])
}

@Test func concurrentMapPreservesOrder() async {
    let result = await [3, 1, 2].concurrentMap { value -> Int in
        try? await Task.sleep(for: .milliseconds(value * 10))
        return value
    }
    #expect(result == [3, 1, 2])
}

@Test func concurrentMapRespectsMaxTasks() async {
    let result = await [1, 2, 3, 4, 5].concurrentMap(maxNumberOfTasks: 2) { $0 * 10 }
    #expect(result == [10, 20, 30, 40, 50])
}

@Test func concurrentMapHandlesEmptySequence() async {
    let result = await [Int]().concurrentMap { $0 * 2 }
    #expect(result.isEmpty)
}

@Test func concurrentMapHandlesSingleElement() async {
    let result = await [42].concurrentMap(maxNumberOfTasks: 3) { $0 * 2 }
    #expect(result == [84])
}

// MARK: - concurrentMap (throwing)
@Test func concurrentMapThrowingTransformsElements() async throws {
    let result = try await [1, 2, 3].concurrentMap { value -> Int in
        try await Task.sleep(for: .milliseconds(1))
        return value * 2
    }
    #expect(result == [2, 4, 6])
}

@Test func concurrentMapThrowingPreservesOrder() async throws {
    let result = try await [3, 1, 2].concurrentMap { value -> Int in
        try await Task.sleep(for: .milliseconds(value * 10))
        return value
    }
    #expect(result == [3, 1, 2])
}

@Test func concurrentMapThrowingRespectsMaxTasks() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentMap(maxNumberOfTasks: 2) { value -> Int in
        try await Task.sleep(for: .milliseconds(1))
        return value * 10
    }
    #expect(result == [10, 20, 30, 40, 50])
}

@Test func concurrentMapThrowingCancelsOnError() async {
    struct TestError: Error {}

    do {
        _ = try await [1, 2, 3].concurrentMap { value -> Int in
            if value == 2 { throw TestError() }
            return value
        }
        Issue.record("Expected error to be thrown")
    } catch {
        #expect(error is TestError)
    }
}
