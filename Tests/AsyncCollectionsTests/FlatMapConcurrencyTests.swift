import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncFlatMap
@Test("asyncFlatMap flattens results")
func async_flat_map_flattens_results() async {
    let result = await [[1, 2], [3, 4], [5]].asyncFlatMap { $0 }
    #expect(result == [1, 2, 3, 4, 5])
}

@Test("asyncFlatMap transforms and flattens")
func async_flat_map_transforms_and_flattens() async {
    let result = await [1, 2, 3].asyncFlatMap { Array(repeating: $0, count: $0) }
    #expect(result == [1, 2, 2, 3, 3, 3])
}

// MARK: - concurrentFlatMap
@Test("concurrentFlatMap flattens results")
func concurrent_flat_map_flattens_results() async {
    let result = await [[1, 2], [3, 4], [5]].concurrentFlatMap { $0 }
    #expect(result == [1, 2, 3, 4, 5])
}

@Test("concurrentFlatMap preserves order")
func concurrent_flat_map_preserves_order() async {
    let result = await [3, 1, 2].concurrentFlatMap { value -> [Int] in
        try? await Task.sleep(for: .milliseconds(value * 10))
        return Array(repeating: value, count: value)
    }
    #expect(result == [3, 3, 3, 1, 2, 2])
}

@Test("concurrentFlatMap handles empty sequence")
func concurrent_flat_map_handles_empty_sequence() async {
    let result = await [Int]().concurrentFlatMap { [$0] }
    #expect(result.isEmpty)
}

@Test("concurrentFlatMap handles empty inner sequences")
func concurrent_flat_map_handles_empty_inner_sequences() async {
    let result = await [1, 2, 3].concurrentFlatMap { _ -> [Int] in [] }
    #expect(result.isEmpty)
}

@Test("concurrentFlatMap respects max tasks")
func concurrent_flat_map_respects_max_tasks() async {
    let result = await [1, 2, 3].concurrentFlatMap(maxNumberOfTasks: 1) { [$0, $0 * 10] }
    #expect(result == [1, 10, 2, 20, 3, 30])
}

// MARK: - concurrentFlatMap (throwing)
@Test("concurrentFlatMap throwing flattens results")
func concurrent_flat_map_throwing_flattens_results() async throws {
    let result = try await [1, 2, 3].concurrentFlatMap { value -> [Int] in
        try await Task.sleep(for: .milliseconds(1))
        return [value, value * 10]
    }
    #expect(result == [1, 10, 2, 20, 3, 30])
}

@Test("concurrentFlatMap throwing preserves order")
func concurrent_flat_map_throwing_preserves_order() async throws {
    let result = try await [3, 1, 2].concurrentFlatMap { value -> [Int] in
        try await Task.sleep(for: .milliseconds(value * 10))
        return Array(repeating: value, count: value)
    }
    #expect(result == [3, 3, 3, 1, 2, 2])
}

@Test("concurrentFlatMap throwing respects max tasks")
func concurrent_flat_map_throwing_respects_max_tasks() async throws {
    let result = try await [1, 2, 3].concurrentFlatMap(maxNumberOfTasks: 2) { value -> [Int] in
        try await Task.sleep(for: .milliseconds(1))
        return [value, value * 10]
    }
    #expect(result == [1, 10, 2, 20, 3, 30])
}

@Test("concurrentFlatMap throwing cancels on error")
func concurrent_flat_map_throwing_cancels_on_error() async {
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
