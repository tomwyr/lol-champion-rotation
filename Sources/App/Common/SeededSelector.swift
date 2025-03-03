import Crypto
import Foundation

struct SeededSelector {
  let seed: Int?

  init(seed: Int? = nil) {
    self.seed = seed
  }

  func select(from elements: [String], taking limit: Int) -> [String] {
    let seed = calcSeed(of: elements)
    var generator = SeededRandomNumberGenerator(seed: seed)
    let shuffled = elements.shuffled(using: &generator)
    return Array(shuffled.prefix(limit))
  }

  private func calcSeed(of elements: [String]) -> UInt64 {
    // Combine the elements and the seed into a string to hash deterministically
    var combinedString = elements.joined()
    if let seed = seed {
      combinedString += String(seed)
    }

    // Use SHA256 for a deterministic hash
    let hashBytes = SHA256.hash(data: Data(combinedString.utf8))
    // Reduce the first 8 bytes into a uint64
    return hashBytes.prefix(8).reduce(0 as UInt64) { $0 << 8 + UInt64($1) }
  }
}

struct SeededRandomNumberGenerator: RandomNumberGenerator {
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
