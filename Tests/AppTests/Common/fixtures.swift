import XCTest

@testable import App

let idHasherSecretKey = "cc6598efe834325043ff59b2627be29c"
let idHasherNonce = "75b7292db9cb"

func nextRotationToken(_ rotationId: String) -> String {
  let tokens = [
    "1": "5f1ae0167844071ce70a764c10ab064ef640019e7768c79ac5456dd4644bd668a9c2e1ec",
    "2": "5f1ae0167844071ce70a764c10ab064ef640019e7768c79ac5456dd4644bd668a9c2e1ef",
    "3": "5f1ae0167844071ce70a764c10ab064ef640019e7768c79ac5456dd4644bd668a9c2e1ee",
    "4": "5f1ae0167844071ce70a764c10ab064ef640019e7768c79ac5456dd4644bd668a9c2e1e9",
    "5": "5f1ae0167844071ce70a764c10ab064ef640019e7768c79ac5456dd4644bd668a9c2e1e8",
  ]
  guard let token = tokens[rotationId] else {
    fatalError("Next rotation token not found for rotation \(rotationId).")
  }
  return token
}

func imageUrl(_ championId: String) -> String {
  "https://api003.backblazeb2.com/file/lol-champion-rotation/champions/\(championId).jpg"
}

func uuid(_ id: String) -> UUID? {
  UUID(uuidString(id))
}

func uuidString(_ id: String) -> String {
  let maxLength = 32
  guard id.count <= maxLength else {
    fatalError("The id must not be longer than \(maxLength) bytes.")
  }
  let leadingZeros = String(repeating: "0", count: maxLength - id.count)
  let str = leadingZeros + id
  return "\(str[0..<8])-\(str[8..<12])-\(str[12..<16])-\(str[16..<20])-\(str[20..<32])"
}
