import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncCompactMap
@Test("asyncCompactMap filters nils")
func async_compact_map_filters_nils() async {
    let result = await [1, nil, 3, nil, 5].asyncCompactMap { $0 }
    #expect(result == [1, 3, 5])
}

@Test("asyncCompactMap transforms and filters")
func async_compact_map_transforms_and_filters() async {
    let result = await ["1", "two", "3"].asyncCompactMap { Int($0) }
    #expect(result == [1, 3])
}

// MARK: - concurrentCompactMap
@Test("concurrentCompactMap filters nils")
func concurrent_compact_map_filters_nils() async {
    let result = await [1, 2, 3, 4, 5].concurrentCompactMap { value -> Int? in
        value.isMultiple(of: 2) ? value : nil
    }
    #expect(result == [2, 4])
}

@Test("concurrentCompactMap preserves order")
func concurrent_compact_map_preserves_order() async {
    let result = await [5, 4, 3, 2, 1].concurrentCompactMap { value -> Int? in
        try? await Task.sleep(for: .milliseconds(value * 10))
        return value > 2 ? value : nil
    }
    #expect(result == [5, 4, 3])
}

@Test("concurrentCompactMap handles empty sequence")
func concurrent_compact_map_handles_empty_sequence() async {
    let result = await [Int]().concurrentCompactMap { value -> Int? in value }
    #expect(result.isEmpty)
}

@Test("concurrentCompactMap returns empty when all nil")
func concurrent_compact_map_returns_empty_when_all_nil() async {
    let result = await [1, 2, 3].concurrentCompactMap { _ -> Int? in nil }
    #expect(result.isEmpty)
}

@Test("concurrentCompactMap respects max tasks")
func concurrent_compact_map_respects_max_tasks() async {
    let result = await [1, 2, 3, 4].concurrentCompactMap(maxNumberOfTasks: 2) { value -> Int? in
        value.isMultiple(of: 2) ? value : nil
    }
    #expect(result == [2, 4])
}

// MARK: - concurrentCompactMap (throwing)
@Test("concurrentCompactMap throwing filters nils")
func concurrent_compact_map_throwing_filters_nils() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentCompactMap { value -> Int? in
        try await Task.sleep(for: .milliseconds(1))
        return value.isMultiple(of: 2) ? value : nil
    }
    #expect(result == [2, 4])
}

@Test("concurrentCompactMap throwing preserves order")
func concurrent_compact_map_throwing_preserves_order() async throws {
    let result = try await [5, 4, 3, 2, 1].concurrentCompactMap { value -> Int? in
        try await Task.sleep(for: .milliseconds(value * 10))
        return value > 2 ? value : nil
    }
    #expect(result == [5, 4, 3])
}

@Test("concurrentCompactMap throwing respects max tasks")
func concurrent_compact_map_throwing_respects_max_tasks() async throws {
    let result = try await [1, 2, 3, 4].concurrentCompactMap(maxNumberOfTasks: 2) { value -> Int? in
        try await Task.sleep(for: .milliseconds(1))
        return value.isMultiple(of: 2) ? value : nil
    }
    #expect(result == [2, 4])
}

@Test("concurrentCompactMap throwing cancels on error")
func concurrent_compact_map_throwing_cancels_on_error() async {
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
