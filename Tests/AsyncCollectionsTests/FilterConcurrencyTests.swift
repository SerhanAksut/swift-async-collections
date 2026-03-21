import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncFilter
@Test("asyncFilter filters elements")
func async_filter_filters_elements() async {
    let result = await [1, 2, 3, 4, 5].asyncFilter { $0.isMultiple(of: 2) }
    #expect(result == [2, 4])
}

@Test("asyncFilter handles empty sequence")
func async_filter_handles_empty_sequence() async {
    let result = await [Int]().asyncFilter { $0 > 0 }
    #expect(result.isEmpty)
}

@Test("asyncFilter with async predicate")
func async_filter_with_async_predicate() async throws {
    let result = try await [1, 2, 3, 4, 5].asyncFilter { value in
        try await Task.sleep(for: .milliseconds(10))
        return value > 3
    }
    #expect(result == [4, 5])
}

// MARK: - concurrentFilter
@Test("concurrentFilter filters elements")
func concurrent_filter_filters_elements() async {
    let result = await [1, 2, 3, 4, 5].concurrentFilter { $0.isMultiple(of: 2) }
    #expect(result == [2, 4])
}

@Test("concurrentFilter preserves order")
func concurrent_filter_preserves_order() async {
    let result = await [5, 4, 3, 2, 1].concurrentFilter { value -> Bool in
        try? await Task.sleep(for: .milliseconds(value * 10))
        return value > 2
    }
    #expect(result == [5, 4, 3])
}

@Test("concurrentFilter respects max tasks")
func concurrent_filter_respects_max_tasks() async {
    let result = await [1, 2, 3, 4, 5].concurrentFilter(maxNumberOfTasks: 2) {
        $0.isMultiple(of: 2)
    }
    #expect(result == [2, 4])
}

@Test("concurrentFilter handles empty sequence")
func concurrent_filter_handles_empty_sequence() async {
    let result = await [Int]().concurrentFilter { $0 > 0 }
    #expect(result.isEmpty)
}

@Test("concurrentFilter includes all elements")
func concurrent_filter_includes_all_elements() async {
    let result = await [1, 2, 3].concurrentFilter { _ in true }
    #expect(result == [1, 2, 3])
}

@Test("concurrentFilter excludes all elements")
func concurrent_filter_excludes_all_elements() async {
    let result = await [1, 2, 3].concurrentFilter { _ in false }
    #expect(result.isEmpty)
}

// MARK: - concurrentFilter (throwing)
@Test("concurrentFilter throwing filters elements")
func concurrent_filter_throwing_filters_elements() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentFilter { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value.isMultiple(of: 2)
    }
    #expect(result == [2, 4])
}

@Test("concurrentFilter throwing preserves order")
func concurrent_filter_throwing_preserves_order() async throws {
    let result = try await [5, 4, 3, 2, 1].concurrentFilter { value -> Bool in
        try await Task.sleep(for: .milliseconds(value * 10))
        return value > 2
    }
    #expect(result == [5, 4, 3])
}

@Test("concurrentFilter throwing respects max tasks")
func concurrent_filter_throwing_respects_max_tasks() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentFilter(maxNumberOfTasks: 2) { value -> Bool in
        try await Task.sleep(for: .milliseconds(1))
        return value.isMultiple(of: 2)
    }
    #expect(result == [2, 4])
}

@Test("concurrentFilter throwing cancels on error")
func concurrent_filter_throwing_cancels_on_error() async {
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
