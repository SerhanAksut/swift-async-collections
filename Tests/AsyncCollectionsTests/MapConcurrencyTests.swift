import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncMap
@Test("asyncMap transforms elements")
func async_map_transforms_elements() async {
    let result = await [1, 2, 3].asyncMap { $0 * 2 }
    #expect(result == [2, 4, 6])
}

@Test("asyncMap preserves order")
func async_map_preserves_order() async throws {
    let result = try await [1, 2, 3].asyncMap { value -> String in
        try await Task.sleep(for: .milliseconds(10))
        return "\(value)"
    }
    #expect(result == ["1", "2", "3"])
}

@Test("asyncMap handles empty sequence")
func async_map_handles_empty_sequence() async {
    let result = await [Int]().asyncMap { $0 * 2 }
    #expect(result.isEmpty)
}

// MARK: - concurrentMap
@Test("concurrentMap transforms elements")
func concurrent_map_transforms_elements() async {
    let result = await [1, 2, 3].concurrentMap { $0 * 2 }
    #expect(result == [2, 4, 6])
}

@Test("concurrentMap preserves order")
func concurrent_map_preserves_order() async {
    let result = await [3, 1, 2].concurrentMap { value -> Int in
        try? await Task.sleep(for: .milliseconds(value * 10))
        return value
    }
    #expect(result == [3, 1, 2])
}

@Test("concurrentMap respects max tasks")
func concurrent_map_respects_max_tasks() async {
    let result = await [1, 2, 3, 4, 5].concurrentMap(maxNumberOfTasks: 2) { $0 * 10 }
    #expect(result == [10, 20, 30, 40, 50])
}

@Test("concurrentMap handles empty sequence")
func concurrent_map_handles_empty_sequence() async {
    let result = await [Int]().concurrentMap { $0 * 2 }
    #expect(result.isEmpty)
}

@Test("concurrentMap handles single element")
func concurrent_map_handles_single_element() async {
    let result = await [42].concurrentMap(maxNumberOfTasks: 3) { $0 * 2 }
    #expect(result == [84])
}

// MARK: - concurrentMap (throwing)
@Test("concurrentMap throwing transforms elements")
func concurrent_map_throwing_transforms_elements() async throws {
    let result = try await [1, 2, 3].concurrentMap { value -> Int in
        try await Task.sleep(for: .milliseconds(1))
        return value * 2
    }
    #expect(result == [2, 4, 6])
}

@Test("concurrentMap throwing preserves order")
func concurrent_map_throwing_preserves_order() async throws {
    let result = try await [3, 1, 2].concurrentMap { value -> Int in
        try await Task.sleep(for: .milliseconds(value * 10))
        return value
    }
    #expect(result == [3, 1, 2])
}

@Test("concurrentMap throwing respects max tasks")
func concurrent_map_throwing_respects_max_tasks() async throws {
    let result = try await [1, 2, 3, 4, 5].concurrentMap(maxNumberOfTasks: 2) { value -> Int in
        try await Task.sleep(for: .milliseconds(1))
        return value * 10
    }
    #expect(result == [10, 20, 30, 40, 50])
}

@Test("concurrentMap throwing cancels on error")
func concurrent_map_throwing_cancels_on_error() async {
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
