import Foundation

final class Mutex<Value: ~Copyable>: @unchecked Sendable {
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
