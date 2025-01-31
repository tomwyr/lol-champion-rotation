import XCTest

@testable import App

let idHasherSecretKey = "cc6598efe834325043ff59b2627be29c"
let idHasherNonce = "75b7292db9cb"

func nextRotationToken(_ rotationId: String) -> String {
  let tokens = [
    "1": "XxrgFnhEBxznCnZMEKsGTvZAAZ53aMeaxUVt1GRL1mipwuHs",
    "2": "XxrgFnhEBxznCnZMEKsGTvZAAZ53aMeaxUVt1GRL1mipwuHv",
    "3": "XxrgFnhEBxznCnZMEKsGTvZAAZ53aMeaxUVt1GRL1mipwuHu",
    "4": "XxrgFnhEBxznCnZMEKsGTvZAAZ53aMeaxUVt1GRL1mipwuHp",
    "5": "XxrgFnhEBxznCnZMEKsGTvZAAZ53aMeaxUVt1GRL1mipwuHo",
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
