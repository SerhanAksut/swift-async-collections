import Foundation
import Testing
@testable import AsyncCollections

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

@Test func concurrentForEachHandlesEmptySequence() async {
    let collected = Mutex([Int]())
    await [Int]().concurrentForEach { value in
        collected.withLock { $0.append(value) }
    }
    let result = collected.withLock { $0 }
    #expect(result.isEmpty)
}

@Test func concurrentForEachHandlesSingleElement() async {
    let collected = Mutex([Int]())
    await [42].concurrentForEach { value in
        collected.withLock { $0.append(value) }
    }
    let result = collected.withLock { $0 }
    #expect(result == [42])
}

// MARK: - concurrentForEach (throwing)
@Test func concurrentForEachThrowingProcessesAllElements() async throws {
    let collected = Mutex([Int]())
    try await [1, 2, 3, 4, 5].concurrentForEach { value in
        try await Task.sleep(for: .milliseconds(1))
        collected.withLock { $0.append(value) }
    }
    let result = collected.withLock { $0.sorted() }
    #expect(result == [1, 2, 3, 4, 5])
}

@Test func concurrentForEachThrowingRespectsMaxTasks() async throws {
    let collected = Mutex([Int]())
    try await [1, 2, 3, 4, 5].concurrentForEach(maxNumberOfTasks: 2) { value in
        try await Task.sleep(for: .milliseconds(1))
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
