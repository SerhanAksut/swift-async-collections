import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncPrefix
@Test("asyncPrefix returns matching prefix")
func async_prefix_returns_matching_prefix() async {
    let result = await [1, 2, 3, 4, 5].asyncPrefix { $0 < 4 }
    #expect(result == [1, 2, 3])
}

@Test("asyncPrefix returns all when all match")
func async_prefix_returns_all_when_all_match() async {
    let result = await [1, 2, 3].asyncPrefix { $0 < 10 }
    #expect(result == [1, 2, 3])
}

@Test("asyncPrefix returns empty when first fails")
func async_prefix_returns_empty_when_first_fails() async {
    let result = await [5, 1, 2].asyncPrefix { $0 < 3 }
    #expect(result == [])
}

@Test("asyncPrefix handles empty sequence")
func async_prefix_handles_empty_sequence() async {
    let result = await [Int]().asyncPrefix { $0 > 0 }
    #expect(result == [])
}

@Test("asyncPrefix handles single element")
func async_prefix_single_element() async {
    let match = await [1].asyncPrefix { $0 < 10 }
    #expect(match == [1])

    let noMatch = await [1].asyncPrefix { $0 > 10 }
    #expect(noMatch == [])
}

@Test("asyncPrefix short-circuits")
func async_prefix_short_circuits() async {
    let counter = Mutex(0)
    let result = await [1, 2, 5, 3, 4].asyncPrefix { value in
        counter.withLock { $0 += 1 }
        return value < 4
    }
    #expect(result == [1, 2])
    let count = counter.withLock { $0 }
    #expect(count == 3)
}

@Test("asyncPrefix does not include elements after break")
func async_prefix_does_not_include_elements_after_break() async {
    let result = await [2, 4, 1, 6, 8].asyncPrefix { $0.isMultiple(of: 2) }
    #expect(result == [2, 4])
}

@Test("asyncPrefix with async predicate")
func async_prefix_with_async_predicate() async throws {
    let result = try await [1, 2, 3, 4, 5].asyncPrefix { value in
        try await Task.sleep(for: .milliseconds(10))
        return value < 4
    }
    #expect(result == [1, 2, 3])
}
