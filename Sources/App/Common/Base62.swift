import BigInt
import Foundation

struct Base62 {
  static func encode(_ input: String, seed: String? = nil) -> String {
    var alphabet = sortedAlphabet
    if let seed {
      var generator = LinearRandomNumberGenerator(seed: fnv1aHash(seed))
      alphabet = alphabet.shuffled(using: &generator)
    }

    let bytes = Array(input.utf8)
    var result = ""

    var value = BigUInt(0)
    for byte in bytes {
      value = (value << 8) | BigUInt(byte)
    }

    while value > 0 {
      let (quotient, remainder) = value.quotientAndRemainder(dividingBy: base)
      result.append(alphabet[Int(remainder)])
      value = quotient
    }

    let leadingZerosCount = bytes.prefix(while: { $0 == 0 }).count
    result.append(String(repeating: zeroChar, count: leadingZerosCount))

    return String(result.reversed())
  }

  static func decode(_ input: String, seed: String? = nil) -> String? {
    var alphabet = sortedAlphabet
    if let seed {
      var generator = LinearRandomNumberGenerator(seed: fnv1aHash(seed))
      alphabet = alphabet.shuffled(using: &generator)
    }

    let alphabetIndex = Dictionary(
      uniqueKeysWithValues: alphabet.enumerated().map { (index, char) in (char, index) }
    )

    var value = BigUInt(0)
    for char in input {
      guard let digitValue = alphabetIndex[char] else {
        return nil
      }
      value = value * base + BigUInt(digitValue)
    }

    var bytes = value.serialize()

    let leadingZerosCount = input.prefix(while: { $0 == zeroChar }).count
    bytes.insert(contentsOf: Array(repeating: 0, count: leadingZerosCount), at: 0)

    return String(data: Data(bytes), encoding: .utf8)
  }
}

private let sortedAlphabet = Array("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
private let base = BigUInt(sortedAlphabet.count)
private let zeroChar = sortedAlphabet.first!

private func fnv1aHash(_ text: String) -> UInt64 {
  var hash: UInt64 = 0xcbf2_9ce4_8422_2325
  let prime: UInt64 = 0x100_0000_01b3
  for byte in text.utf8 {
    hash ^= UInt64(byte)
    hash &*= prime
  }
  return hash
}
