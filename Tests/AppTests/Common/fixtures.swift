import XCTest

@testable import App

let idHasherSeed = "hq9fh01k7tio5l40tdc8uhs4e0pb4i93"

func nextRotationToken(_ rotationId: String) -> String {
  let tokens = [
    "1": "nLzBS1CFLUWAsVHZz7kzWaU36Tr8tEyKIQTLG1loIIidtmez",
    "2": "nLzBS1CFLUWAsVHZz7kzWaU36Tr8tEyKIQTLG1loIIidtmeW",
    "3": "nLzBS1CFLUWAsVHZz7kzWaU36Tr8tEyKIQTLG1loIIidtmeJ",
    "4": "nLzBS1CFLUWAsVHZz7kzWaU36Tr8tEyKIQTLG1loIIidtmeh",
    "5": "nLzBS1CFLUWAsVHZz7kzWaU36Tr8tEyKIQTLG1loIIidtmeR",
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
