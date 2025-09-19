import Clocks
import Testing

@testable import App

@Suite struct RunRetryingTests: @unchecked Sendable {
  var task = TestTask()
  var clock = TestClock()

  let returnFive: () throws -> Int = { 5 }
  let throwExpectedError: () throws -> Int = { throw TestTaskError() }
  let throwUnexpectedError: () throws -> Int = { throw TestTaskUnexpectedError() }

  init() throws {
    task = TestTask()
    clock = TestClock()
  }

  @Test func nonFailingTask() async throws {
    let result = try await task.runRetrying(retryDelays: [], clock: clock) {
      5
    }

    #expect(result == 5)
  }

  @Test func taskRecovery() async throws {
    var results = [throwExpectedError, returnFive]

    async let asyncResult = task.runRetrying(
      retryDelays: [.seconds(1)],
      clock: clock
    ) {
      try results.removeFirst()()
    }

    await clock.advance(by: .seconds(2))

    let result = try await asyncResult

    #expect(result == 5)
  }

  @Test func retriesOrder() async throws {
    var results = [
      throwExpectedError, throwExpectedError, throwExpectedError, throwExpectedError, returnFive,
    ]

    let attempts = Counter()

    async let asyncResult = task.runRetrying(
      retryDelays: [.seconds(1), .seconds(2), .seconds(3), .seconds(4)],
      clock: clock
    ) {
      await attempts.increment()
      return try results.removeFirst()()
    }

    await clock.advance()

    // 0 seconds in total.
    #expect(await attempts.value == 1)

    await clock.advance(by: .seconds(2))

    // 2 seconds in total.
    #expect(await attempts.value == 2)

    await clock.advance(by: .seconds(2))

    // 4 seconds in total.
    #expect(await attempts.value == 3)

    await clock.advance(by: .seconds(3))

    // 7 seconds in total.
    #expect(await attempts.value == 4)

    await clock.advance(by: .seconds(4))

    // 11 seconds in total.
    #expect(await attempts.value == 5)

    let result = try await asyncResult

    #expect(result == 5)
  }

  @Test func moreErrorsThanRetries() async throws {
    var results = [throwExpectedError, throwExpectedError, returnFive]

    async let asyncResult = task.runRetrying(
      retryDelays: [.seconds(1)],
      clock: clock
    ) {
      try results.removeFirst()()
    }

    await clock.advance(by: .seconds(2))

    do {
      _ = try await asyncResult
      Issue.record("Async operation that was expected to fail succeeded")
    } catch is TestTaskError {
      // Pass
    } catch {
      Issue.record("Async operation that was expected to fail threw an unexpected error")
    }
  }

  @Test func expectedErrorFilter() async throws {
    var results = [throwExpectedError, returnFive]

    async let asyncResult = task.runRetrying(
      retryDelays: [.seconds(1)],
      errorFilter: { error in error is TestTaskError },
      clock: clock
    ) {
      try results.removeFirst()()
    }

    await clock.advance(by: .seconds(2))

    let result = try await asyncResult

    #expect(result == 5)
  }

  @Test func unexpectedError() async throws {
    await #expect(throws: TestTaskUnexpectedError.self) {
      var results = [throwUnexpectedError, returnFive]

      async let asyncResult = task.runRetrying(
        retryDelays: [.seconds(1)],
        errorFilter: { error in error is TestTaskError },
        clock: clock
      ) {
        try results.removeFirst()()
      }

      await clock.advance(by: .seconds(2))

      _ = try await asyncResult
    }
  }
}

struct TestTask: RunRetrying {}

struct TestTaskError: Error {}

struct TestTaskUnexpectedError: Error {}

extension Duration {
  static func seconds(_ amount: Int64) -> Duration {
    .init(.seconds(amount))
  }
}

private actor Counter {
  var value = 0

  func increment() {
    value += 1
  }
}
