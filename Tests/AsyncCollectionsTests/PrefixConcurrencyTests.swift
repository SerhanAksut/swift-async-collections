import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncPrefix
@Test func asyncPrefixReturnsMatchingPrefix() async {
    let result = await [1, 2, 3, 4, 5].asyncPrefix { $0 < 4 }
    #expect(result == [1, 2, 3])
}

@Test func asyncPrefixReturnsAllWhenAllMatch() async {
    let result = await [1, 2, 3].asyncPrefix { $0 < 10 }
    #expect(result == [1, 2, 3])
}

@Test func asyncPrefixReturnsEmptyWhenFirstFails() async {
    let result = await [5, 1, 2].asyncPrefix { $0 < 3 }
    #expect(result == [])
}

@Test func asyncPrefixHandlesEmptySequence() async {
    let result = await [Int]().asyncPrefix { $0 > 0 }
    #expect(result == [])
}

@Test func asyncPrefixSingleElement() async {
    let match = await [1].asyncPrefix { $0 < 10 }
    #expect(match == [1])

    let noMatch = await [1].asyncPrefix { $0 > 10 }
    #expect(noMatch == [])
}

@Test func asyncPrefixShortCircuits() async {
    let counter = Mutex(0)
    let result = await [1, 2, 5, 3, 4].asyncPrefix { value in
        counter.withLock { $0 += 1 }
        return value < 4
    }
    #expect(result == [1, 2])
    let count = counter.withLock { $0 }
    #expect(count == 3)
}

@Test func asyncPrefixDoesNotIncludeElementsAfterBreak() async {
    let result = await [2, 4, 1, 6, 8].asyncPrefix { $0.isMultiple(of: 2) }
    #expect(result == [2, 4])
}

@Test func asyncPrefixWithAsyncPredicate() async throws {
    let result = try await [1, 2, 3, 4, 5].asyncPrefix { value in
        try await Task.sleep(for: .milliseconds(10))
        return value < 4
    }
    #expect(result == [1, 2, 3])
}
