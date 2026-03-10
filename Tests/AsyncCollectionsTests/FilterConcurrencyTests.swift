import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncFilter
@Test func asyncFilterFiltersElements() async {
    let result = await [1, 2, 3, 4, 5].asyncFilter { $0.isMultiple(of: 2) }
    #expect(result == [2, 4])
}

@Test func asyncFilterHandlesEmptySequence() async {
    let result = await [Int]().asyncFilter { $0 > 0 }
    #expect(result.isEmpty)
}

@Test func asyncFilterWithAsyncPredicate() async throws {
    let result = try await [1, 2, 3, 4, 5].asyncFilter { value in
        try await Task.sleep(for: .milliseconds(10))
        return value > 3
    }
    #expect(result == [4, 5])
}

// MARK: - concurrentFilter
@Test func concurrentFilterFiltersElements() async {
    let result = await [1, 2, 3, 4, 5].concurrentFilter { $0.isMultiple(of: 2) }
    #expect(result == [2, 4])
}

@Test func concurrentFilterPreservesOrder() async {
    let result = await [5, 4, 3, 2, 1].concurrentFilter { value -> Bool in
        try? await Task.sleep(for: .milliseconds(value * 10))
        return value > 2
    }
    #expect(result == [5, 4, 3])
}

@Test func concurrentFilterRespectsMaxTasks() async {
    let result = await [1, 2, 3, 4, 5].concurrentFilter(maxNumberOfTasks: 2) {
        $0.isMultiple(of: 2)
    }
    #expect(result == [2, 4])
}

@Test func concurrentFilterHandlesEmptySequence() async {
    let result = await [Int]().concurrentFilter { $0 > 0 }
    #expect(result.isEmpty)
}

@Test func concurrentFilterIncludesAllElements() async {
    let result = await [1, 2, 3].concurrentFilter { _ in true }
    #expect(result == [1, 2, 3])
}

@Test func concurrentFilterExcludesAllElements() async {
    let result = await [1, 2, 3].concurrentFilter { _ in false }
    #expect(result.isEmpty)
}

// MARK: - concurrentFilter (throwing)
@Test func concurrentFilterThrowingFiltersElements() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentFilter { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value.isMultiple(of: 2)
    }
    #expect(result == [2, 4])
}

@Test func concurrentFilterThrowingPreservesOrder() async throws {
    let result = try await [5, 4, 3, 2, 1].concurrentFilter { value -> Bool in
        try await Task.sleep(for: .milliseconds(value * 10))
        return value > 2
    }
    #expect(result == [5, 4, 3])
}

@Test func concurrentFilterThrowingRespectsMaxTasks() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentFilter(maxNumberOfTasks: 2) { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value.isMultiple(of: 2)
    }
    #expect(result == [2, 4])
}

@Test func concurrentFilterThrowingCancelsOnError() async {
    struct TestError: Error {}

    do {
        _ = try await [1, 2, 3].concurrentFilter { value -> Bool in
            if value == 2 { throw TestError() }
            return true
        }
        Issue.record("Expected error to be thrown")
    } catch {
        #expect(error is TestError)
    }
}
