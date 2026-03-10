import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncReduce
@Test func asyncReduceAccumulatesResult() async {
    let result = await [1, 2, 3, 4].asyncReduce(0) { $0 + $1 }
    #expect(result == 10)
}

@Test func asyncReduceHandlesEmptySequence() async {
    let result = await [Int]().asyncReduce(42) { $0 + $1 }
    #expect(result == 42)
}

@Test func asyncReduceIntoAccumulatesResult() async {
    let result = await [1, 2, 3].asyncReduce(into: [String]()) { acc, value in
        acc.append("\(value)")
    }
    #expect(result == ["1", "2", "3"])
}

@Test func asyncReduceWithAsyncOperation() async throws {
    let result = try await [1, 2, 3].asyncReduce(0) { acc, value in
        try await Task.sleep(for: .milliseconds(10))
        return acc + value
    }
    #expect(result == 6)
}

@Test func asyncReduceThrowingPropagatesError() async {
    struct TestError: Error {}

    do {
        _ = try await [1, 2, 3].asyncReduce(0) { acc, value in
            if value == 2 { throw TestError() }
            return acc + value
        }
        Issue.record("Expected error to be thrown")
    } catch {
        #expect(error is TestError)
    }
}
