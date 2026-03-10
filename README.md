# AsyncCollections

Async and concurrent extensions for Swift's `Sequence` type, built on structured concurrency.

## Features

- **Sequential async** - `asyncMap`, `asyncCompactMap`, `asyncFlatMap`, `asyncForEach`, `asyncFilter`, `asyncReduce`
- **Concurrent** - `concurrentMap`, `concurrentCompactMap`, `concurrentFlatMap`, `concurrentForEach`, `concurrentFilter`
- Order-preserving results for all `map`/`compactMap`/`flatMap`/`filter` variants
- Optional `maxNumberOfTasks` to limit parallelism
- Automatic cancellation propagation via `TaskGroup`
- Throwing variants with first-error cancellation via `ThrowingTaskGroup`
- Swift 6 strict concurrency compatible

## Installation

### Swift Package Manager

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/serhanaksut/swift-async-collections.git", from: "1.1.0")
]
```

Then add `"AsyncCollections"` to your target's dependencies:

```swift
.target(name: "YourTarget", dependencies: ["AsyncCollections"])
```

## Usage

### Sequential async operations

Process elements one at a time, awaiting each before starting the next:

```swift
let data = try await urls.asyncMap { try await URLSession.shared.data(from: $0).0 }

let validUsers = try await ids.asyncCompactMap { try await fetchUserIfExists(id: $0) }

let allPosts = try await users.asyncFlatMap { try await fetchPosts(for: $0) }

try await items.asyncForEach { try await save($0) }

let activeUsers = try await users.asyncFilter { try await checkIsActive($0) }

let total = try await invoices.asyncReduce(0) { sum, invoice in
    try await sum + fetchAmount(for: invoice)
}

let usersByID = try await users.asyncReduce(into: [:]) { dict, user in
    dict[user.id] = try await fetchProfile(for: user)
}
```

### Concurrent operations

Process all elements in parallel using structured concurrency:

```swift
let data = try await urls.concurrentMap { try await URLSession.shared.data(from: $0).0 }

let validUsers = try await ids.concurrentCompactMap { try await fetchUserIfExists(id: $0) }

let allPosts = try await users.concurrentFlatMap { try await fetchPosts(for: $0) }

try await items.concurrentForEach { try await upload($0) }

let activeUsers = try await users.concurrentFilter { try await checkIsActive($0) }
```

### Limiting parallelism

Use `maxNumberOfTasks` to cap the number of concurrent operations:

```swift
// At most 5 downloads at a time
let images = try await urls.concurrentMap(maxNumberOfTasks: 5) {
    try await downloadImage(from: $0)
}
```

## Requirements

- Swift 6.0+
- iOS 16+ / macOS 13+ / tvOS 16+ / watchOS 9+ / visionOS 1+

## License

MIT - see [LICENSE](LICENSE) for details.
