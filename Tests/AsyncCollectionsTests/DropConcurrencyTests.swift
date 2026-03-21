import Foundation
import Testing
@testable import AsyncCollections

// MARK: - asyncDrop
@Test("asyncDrop removes matching prefix")
func async_drop_removes_matching_prefix() async {
    let result = await [1, 2, 3, 4, 5].asyncDrop { $0 < 3 }
    #expect(result == [3, 4, 5])
}

@Test("asyncDrop removes all when all match")
func async_drop_removes_all_when_all_match() async {
    let result = await [1, 2, 3].asyncDrop { $0 < 10 }
    #expect(result == [])
}

@Test("asyncDrop removes none when first fails")
func async_drop_removes_none_when_first_fails() async {
    let result = await [5, 1, 2].asyncDrop { $0 < 3 }
    #expect(result == [5, 1, 2])
}

@Test("asyncDrop handles empty sequence")
func async_drop_handles_empty_sequence() async {
    let result = await [Int]().asyncDrop { $0 > 0 }
    #expect(result == [])
}

@Test("asyncDrop handles single element")
func async_drop_single_element() async {
    let match = await [1].asyncDrop { $0 < 10 }
    #expect(match == [])

    let noMatch = await [1].asyncDrop { $0 > 10 }
    #expect(noMatch == [1])
}

@Test("asyncDrop stops checking after first failure")
func async_drop_stops_checking_after_first_failure() async {
    let counter = Mutex(0)
    let result = await [1, 2, 5, 3, 4].asyncDrop { value in
        counter.withLock { $0 += 1 }
        return value < 4
    }
    #expect(result == [5, 3, 4])
    let count = counter.withLock { $0 }
    #expect(count == 3)
}

@Test("asyncDrop includes later matching elements")
func async_drop_includes_later_matching_elements() async {
    let result = await [2, 4, 1, 6, 8].asyncDrop { $0.isMultiple(of: 2) }
    #expect(result == [1, 6, 8])
}

@Test("asyncDrop with async predicate")
func async_drop_with_async_predicate() async throws {
    let result = try await [1, 2, 3, 4, 5].asyncDrop { value in
        try await Task.sleep(for: .milliseconds(10))
        return value < 3
    }
    #expect(result == [3, 4, 5])
}
