import Crypto
import Foundation

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

func calcSeed(of elements: [String], seed: String? = nil) -> UInt64 {
  // Combine the elements and the seed into a string to hash deterministically
  calcSeed(of: elements.joined(), seed: seed)
}

func calcSeed(of element: String, seed: String? = nil) -> UInt64 {
  var combinedString = element
  if let seed = seed {
    combinedString += String(seed)
  }

  // Use SHA256 for a deterministic hash
  let hashBytes = SHA256.hash(data: Data(combinedString.utf8))
  // Reduce the first 8 bytes into a uint64
  return hashBytes.prefix(8).reduce(0 as UInt64) { $0 << 8 + UInt64($1) }
}
