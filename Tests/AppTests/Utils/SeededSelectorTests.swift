import XCTest

@testable import App

final class SeededSelectorTests: XCTestCase {
  func testEmpty() {
    let selector = SeededSelector()
    let result = selector.select(from: [], taking: 5)
    XCTAssertEqual(result, [])
  }

  func testSingleElement() {
    let selector = SeededSelector()
    let result = selector.select(from: ["1"], taking: 1)
    XCTAssertEqual(result, ["1"])
  }

  func testFewerElementsThanLimit() {
    let selector = SeededSelector()
    let result = selector.select(from: ["1", "2", "3"], taking: 5)
    XCTAssertEqual(result, ["1", "3", "2"])
  }

  func testMoreElementsThanLimit() {
    let selector = SeededSelector()
    let result = selector.select(from: ["1", "2", "3", "4", "5", "6", "7"], taking: 5)
    XCTAssertEqual(result, ["2", "6", "4", "3", "1"])
  }

  func testPreSeededSelector() {
    let selector = SeededSelector(seed: 320_751_247)
    let result = selector.select(from: ["1", "2", "3", "4", "5", "6", "7"], taking: 5)
    XCTAssertEqual(result, ["4", "2", "6", "5", "7"])
  }
}
