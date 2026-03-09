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

@Test func concurrentCompactMapRespectsMaxTasks() async {
    let result = await [1, 2, 3, 4].concurrentCompactMap(maxNumberOfTasks: 2) { value -> Int? in
        value.isMultiple(of: 2) ? value : nil
    }
    #expect(result == [2, 4])
}

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

@Test func concurrentFlatMapRespectsMaxTasks() async {
    let result = await [1, 2, 3].concurrentFlatMap(maxNumberOfTasks: 1) { [$0, $0 * 10] }
    #expect(result == [1, 10, 2, 20, 3, 30])
}

// MARK: - asyncForEach
@Test func asyncForEachProcessesAllElements() async {
    var collected = [Int]()
    await [1, 2, 3].asyncForEach { collected.append($0) }
    #expect(collected == [1, 2, 3])
}

// MARK: - concurrentForEach
@Test func concurrentForEachProcessesAllElements() async {
    let collected = Mutex([Int]())
    await [1, 2, 3, 4, 5].concurrentForEach { value in
        collected.withLock { $0.append(value) }
    }
    let result = collected.withLock { $0.sorted() }
    #expect(result == [1, 2, 3, 4, 5])
}

@Test func concurrentForEachRespectsMaxTasks() async {
    let collected = Mutex([Int]())
    await [1, 2, 3, 4, 5].concurrentForEach(maxNumberOfTasks: 2) { value in
        collected.withLock { $0.append(value) }
    }
    let result = collected.withLock { $0.sorted() }
    #expect(result == [1, 2, 3, 4, 5])
}

@Test func concurrentForEachThrowingPropagatesError() async {
    struct TestError: Error {}

    do {
        try await [1, 2, 3].concurrentForEach { value in
            if value == 2 { throw TestError() }
        }
        Issue.record("Expected error to be thrown")
    } catch {
        #expect(error is TestError)
    }
}

// MARK: - Mutex (test utility)

private final class Mutex<Value: ~Copyable>: @unchecked Sendable {
    private var _value: Value
    private let lock = NSLock()

    init(_ value: consuming sending Value) {
        self._value = value
    }

    func withLock<Result>(_ body: (inout Value) -> Result) -> Result {
        lock.lock()
        defer { lock.unlock() }
        return body(&_value)
    }
}
