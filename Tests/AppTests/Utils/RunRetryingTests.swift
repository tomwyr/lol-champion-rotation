import Clocks
import XCTest

@testable import App

final class RunRetryingTests: XCTestCase, @unchecked Sendable {
  var task = TestTask()
  var clock = TestClock()

  let five: () throws -> Int = { 5 }
  let error: () throws -> Int = { throw TestTaskError() }
  let unexpectedError: () throws -> Int = { throw TestTaskUnexpectedError() }

  override func setUp() async throws {
    task = TestTask()
    clock = TestClock()
  }

  func testNonFailingTask() async throws {
    let result = try await task.runRetrying(retryDelays: [], clock: clock) {
      5
    }

    XCTAssertEqual(result, 5)
  }

  func testTaskRecovery() async throws {
    var results = [error, five]

    async let asyncResult = task.runRetrying(
      retryDelays: [.seconds(1)],
      clock: clock
    ) {
      try results.removeFirst()()
    }

    await clock.advance(by: .seconds(2))

    let result = try await asyncResult

    XCTAssertEqual(result, 5)
  }

  func testRetriesOrder() async throws {
    var results = [error, error, error, error, five]

    var attempts = 0

    async let asyncResult = task.runRetrying(
      retryDelays: [.seconds(1), .seconds(2), .seconds(3), .seconds(4)],
      clock: clock
    ) {
      attempts += 1
      return try results.removeFirst()()
    }

    await clock.advance()

    // 0 seconds in total.
    XCTAssertEqual(attempts, 1)

    await clock.advance(by: .seconds(2))

    // 2 seconds in total.
    XCTAssertEqual(attempts, 2)

    await clock.advance(by: .seconds(2))

    // 4 seconds in total.
    XCTAssertEqual(attempts, 3)

    await clock.advance(by: .seconds(3))

    // 7 seconds in total.
    XCTAssertEqual(attempts, 4)

    await clock.advance(by: .seconds(4))

    // 11 seconds in total.
    XCTAssertEqual(attempts, 5)

    let result = try await asyncResult

    XCTAssertEqual(result, 5)
  }

  func testMoreErrorsThanRetries() async throws {
    var results = [error, error, five]

    async let asyncResult = task.runRetrying(
      retryDelays: [.seconds(1)],
      clock: clock
    ) {
      try results.removeFirst()()
    }

    await clock.advance(by: .seconds(2))

    do {
      _ = try await asyncResult
      XCTFail("Async operation that was expected to fail succeeded")
    } catch is TestTaskError {
      // Pass
    } catch {
      XCTFail("Async operation that was expected to fail threw an unexpected error")
    }
  }

  func testExpectedErrorFilter() async throws {
    var results = [error, five]

    async let asyncResult = task.runRetrying(
      retryDelays: [.seconds(1)],
      errorFilter: { error in error is TestTaskError },
      clock: clock
    ) {
      try results.removeFirst()()
    }

    await clock.advance(by: .seconds(2))

    let result = try await asyncResult

    XCTAssertEqual(result, 5)
  }

  func testUnexpectedError() async throws {
    var results = [unexpectedError, five]

    async let asyncResult = task.runRetrying(
      retryDelays: [.seconds(1)],
      errorFilter: { error in error is TestTaskError },
      clock: clock
    ) {
      try results.removeFirst()()
    }

    await clock.advance(by: .seconds(2))

    do {
      _ = try await asyncResult
      XCTFail("Async operation that was expected to fail succeeded")
    } catch is TestTaskUnexpectedError {
      // Pass
    } catch {
      XCTFail("Async operation that was expected to fail threw an unexpected error")
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
