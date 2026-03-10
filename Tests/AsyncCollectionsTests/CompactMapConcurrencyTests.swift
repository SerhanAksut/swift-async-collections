import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncCompactMap
@Test func asyncCompactMapFiltersNils() async {
    let result = await [1, nil, 3, nil, 5].asyncCompactMap { $0 }
    #expect(result == [1, 3, 5])
}

@Test func asyncCompactMapTransformsAndFilters() async {
    let result = await ["1", "two", "3"].asyncCompactMap { Int($0) }
    #expect(result == [1, 3])
}

// MARK: - concurrentCompactMap
@Test func concurrentCompactMapFiltersNils() async {
    let result = await [1, 2, 3, 4, 5].concurrentCompactMap { value -> Int? in
        value.isMultiple(of: 2) ? value : nil
    }
    #expect(result == [2, 4])
}

@Test func concurrentCompactMapPreservesOrder() async {
    let result = await [5, 4, 3, 2, 1].concurrentCompactMap { value -> Int? in
        try? await Task.sleep(for: .milliseconds(value * 10))
        return value > 2 ? value : nil
    }
    #expect(result == [5, 4, 3])
}

@Test func concurrentCompactMapHandlesEmptySequence() async {
    let result = await [Int]().concurrentCompactMap { value -> Int? in value }
    #expect(result.isEmpty)
}

@Test func concurrentCompactMapReturnsEmptyWhenAllNil() async {
    let result = await [1, 2, 3].concurrentCompactMap { _ -> Int? in nil }
    #expect(result.isEmpty)
}

@Test func concurrentCompactMapRespectsMaxTasks() async {
    let result = await [1, 2, 3, 4].concurrentCompactMap(maxNumberOfTasks: 2) { value -> Int? in
        value.isMultiple(of: 2) ? value : nil
    }
    #expect(result == [2, 4])
}

// MARK: - concurrentCompactMap (throwing)
@Test func concurrentCompactMapThrowingFiltersNils() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentCompactMap { value -> Int? in
        try await Task.sleep(for: .milliseconds(1))
        return value.isMultiple(of: 2) ? value : nil
    }
    #expect(result == [2, 4])
}

@Test func concurrentCompactMapThrowingPreservesOrder() async throws {
    let result = try await [5, 4, 3, 2, 1].concurrentCompactMap { value -> Int? in
        try await Task.sleep(for: .milliseconds(value * 10))
        return value > 2 ? value : nil
    }
    #expect(result == [5, 4, 3])
}

@Test func concurrentCompactMapThrowingRespectsMaxTasks() async throws {
    let result = try await [1, 2, 3, 4].concurrentCompactMap(maxNumberOfTasks: 2) { value -> Int? in
        try await Task.sleep(for: .milliseconds(1))
        return value.isMultiple(of: 2) ? value : nil
    }
    #expect(result == [2, 4])
}

@Test func concurrentCompactMapThrowingCancelsOnError() async {
    struct TestError: Error {}

    do {
        _ = try await [1, 2, 3].concurrentCompactMap { value -> Int? in
            if value == 2 { throw TestError() }
            return value
        }
        Issue.record("Expected error to be thrown")
    } catch {
        #expect(error is TestError)
    }
}
