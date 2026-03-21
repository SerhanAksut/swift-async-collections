import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncDrop
@Test func asyncDropRemovesMatchingPrefix() async {
    let result = await [1, 2, 3, 4, 5].asyncDrop { $0 < 3 }
    #expect(result == [3, 4, 5])
}

@Test func asyncDropRemovesAllWhenAllMatch() async {
    let result = await [1, 2, 3].asyncDrop { $0 < 10 }
    #expect(result == [])
}

@Test func asyncDropRemovesNoneWhenFirstFails() async {
    let result = await [5, 1, 2].asyncDrop { $0 < 3 }
    #expect(result == [5, 1, 2])
}

@Test func asyncDropHandlesEmptySequence() async {
    let result = await [Int]().asyncDrop { $0 > 0 }
    #expect(result == [])
}

@Test func asyncDropSingleElement() async {
    let match = await [1].asyncDrop { $0 < 10 }
    #expect(match == [])

    let noMatch = await [1].asyncDrop { $0 > 10 }
    #expect(noMatch == [1])
}

@Test func asyncDropStopsCheckingAfterFirstFailure() async {
    let counter = Mutex(0)
    let result = await [1, 2, 5, 3, 4].asyncDrop { value in
        counter.withLock { $0 += 1 }
        return value < 4
    }
    #expect(result == [5, 3, 4])
    let count = counter.withLock { $0 }
    #expect(count == 3)
}

@Test func asyncDropIncludesLaterMatchingElements() async {
    let result = await [2, 4, 1, 6, 8].asyncDrop { $0.isMultiple(of: 2) }
    #expect(result == [1, 6, 8])
}

@Test func asyncDropWithAsyncPredicate() async throws {
    let result = try await [1, 2, 3, 4, 5].asyncDrop { value in
        try await Task.sleep(for: .milliseconds(10))
        return value < 3
    }
    #expect(result == [3, 4, 5])
}
