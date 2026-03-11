import Clocks
import Testing

@testable import App

@Suite struct WithTimeoutTests {
  var task = TestTask()
  var clock = TestClock()

  init() {
    task = TestTask()
    clock = TestClock()
  }

  @Test func immediateCompletion() async throws {
    async let result = task.withTimeout(of: .seconds(1), clock: clock) {
      "Success"
    }
    #expect(try await result == "Success")
  }

  @Test func completionWithinTimeout() async throws {
    async let result = task.withTimeout(of: .seconds(1), clock: clock) {
      try await Task.sleep(for: .milliseconds(500), clock: clock)
      return "Success"
    }
    await clock.advance(by: .milliseconds(500))
    #expect(try await result == "Success")
  }

  @Test func timeoutExceeded() async {
    await #expect(throws: TaskTimeoutError.self) {
      async let result = task.withTimeout(of: .seconds(1), clock: clock) {
        try await Task.sleep(for: .seconds(3), clock: clock)
        return "Success"
      }
      await clock.advance(by: .seconds(2))
      return try await result
    }
  }

  @Test func taskThrowsError() async {
    await #expect(throws: TestTaskError.self) {
      try await task.withTimeout(of: .seconds(1), clock: clock) {
        throw TestTaskError()
      }
    }
  }

  @Test func explicitCancellation() async {
    let parent = Task {
      try await task.withTimeout(of: .seconds(1), clock: clock) {
        try await Task.sleep(for: .seconds(3), clock: clock)
        return "Success"
      }
    }

    parent.cancel()

    await #expect(throws: CancellationError.self) {
      try await parent.value
    }
  }

  struct TestTask: WithTimeout {}
  struct TestTaskError: Error {}
}
