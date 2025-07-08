import Testing

@testable import App

@Suite struct SeededSelectorTests {
  @Test func empty() {
    let selector = SeededSelector()
    let result = selector.select(from: [], taking: 5)
    #expect(result == [])
  }

  @Test func singleElement() {
    let selector = SeededSelector()
    let result = selector.select(from: ["1"], taking: 1)
    #expect(result == ["1"])
  }

  @Test func fewerElementsThanLimit() {
    let selector = SeededSelector()
    let result = selector.select(from: ["1", "2", "3"], taking: 5)
    #expect(result == ["1", "3", "2"])
  }

  @Test func moreElementsThanLimit() {
    let selector = SeededSelector()
    let result = selector.select(from: ["1", "2", "3", "4", "5", "6", "7"], taking: 5)
    #expect(result == ["2", "6", "4", "3", "1"])
  }

  @Test func preSeededSelector() {
    let selector = SeededSelector(seed: 320_751_247)
    let result = selector.select(from: ["1", "2", "3", "4", "5", "6", "7"], taking: 5)
    #expect(result == ["4", "2", "6", "5", "7"])
  }
}
