import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncFlatMap
@Test func asyncFlatMapFlattensResults() async {
    let result = await [[1, 2], [3, 4], [5]].asyncFlatMap { $0 }
    #expect(result == [1, 2, 3, 4, 5])
}

@Test func asyncFlatMapTransformsAndFlattens() async {
    let result = await [1, 2, 3].asyncFlatMap { Array(repeating: $0, count: $0) }
    #expect(result == [1, 2, 2, 3, 3, 3])
}

// MARK: - concurrentFlatMap
@Test func concurrentFlatMapFlattensResults() async {
    let result = await [[1, 2], [3, 4], [5]].concurrentFlatMap { $0 }
    #expect(result == [1, 2, 3, 4, 5])
}

@Test func concurrentFlatMapPreservesOrder() async {
    let result = await [3, 1, 2].concurrentFlatMap { value -> [Int] in
        try? await Task.sleep(for: .milliseconds(value * 10))
        return Array(repeating: value, count: value)
    }
    #expect(result == [3, 3, 3, 1, 2, 2])
}

@Test func concurrentFlatMapHandlesEmptySequence() async {
    let result = await [Int]().concurrentFlatMap { [$0] }
    #expect(result.isEmpty)
}

@Test func concurrentFlatMapHandlesEmptyInnerSequences() async {
    let result = await [1, 2, 3].concurrentFlatMap { _ -> [Int] in [] }
    #expect(result.isEmpty)
}

@Test func concurrentFlatMapRespectsMaxTasks() async {
    let result = await [1, 2, 3].concurrentFlatMap(maxNumberOfTasks: 1) { [$0, $0 * 10] }
    #expect(result == [1, 10, 2, 20, 3, 30])
}

// MARK: - concurrentFlatMap (throwing)
@Test func concurrentFlatMapThrowingFlattensResults() async throws {
    let result = try await [1, 2, 3].concurrentFlatMap { value -> [Int] in
        try await Task.sleep(for: .milliseconds(1))
        return [value, value * 10]
    }
    #expect(result == [1, 10, 2, 20, 3, 30])
}

@Test func concurrentFlatMapThrowingPreservesOrder() async throws {
    let result = try await [3, 1, 2].concurrentFlatMap { value -> [Int] in
        try await Task.sleep(for: .milliseconds(value * 10))
        return Array(repeating: value, count: value)
    }
    #expect(result == [3, 3, 3, 1, 2, 2])
}

@Test func concurrentFlatMapThrowingRespectsMaxTasks() async throws {
    let result = try await [1, 2, 3].concurrentFlatMap(maxNumberOfTasks: 2) { value -> [Int] in
        try await Task.sleep(for: .milliseconds(1))
        return [value, value * 10]
    }
    #expect(result == [1, 10, 2, 20, 3, 30])
}

@Test func concurrentFlatMapThrowingCancelsOnError() async {
    struct TestError: Error {}

    do {
        _ = try await [1, 2, 3].concurrentFlatMap { value -> [Int] in
            if value == 2 { throw TestError() }
            return [value]
        }
        Issue.record("Expected error to be thrown")
    } catch {
        #expect(error is TestError)
    }
}
