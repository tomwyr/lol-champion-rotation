struct LinearRandomNumberGenerator: RandomNumberGenerator {
  private var state: UInt64

  init(seed: UInt64) {
    self.state = seed
  }

  mutating func next() -> UInt64 {
    // Step by a constant prime number
    state &+= 0x9E37_79B9_7F4A_7C15
    return state
  }
}
