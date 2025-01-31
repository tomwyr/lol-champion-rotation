import CryptoKit
import XCTest

@testable import App

final class IdHasherTests: XCTestCase {
  let hasher = IdHasher(
    secretKey: "2812b3f1a5eed1c3a9d19764bfd3b32f",
    nonce: "a5132d9e29ba"
  )

  let ids = [
    "71343685-a356-4e3a-816a-affb29575bb8",
    "67933e36-d0ae-4b11-92fe-f11be661d513",
    "13d46ed5-818d-4e13-88c3-c32e653b577b",
    "03529c02-1da8-4feb-88d8-21baddd096c8",
    "0e10c150-7565-4802-a5f2-b715641bb23e",
  ]

  let tokens = [
    "sL21JAo5lMjHN2PuU51gYl6957w30qbbfgrZKJQonLPWkhyE",
    "sbu/Iwpqn8vHMmC6AJ1gZVzt5700gqLbeV2OKMMnn7WHxU+P",
    "tr/iJA9qyMjHbmHjAZ1gYlzv57w+h/TbfF+NL5AkmubWx0ne",
    "t7+zIgBsnM/HZzS6XZ1gYQi+57w+gP/bLV3dK8J1zbTaxh2E",
    "t+m3IFo+mc3HYWXtUJ1gP13u5+UzgvXbfVuOf5AlmOaBwk3Z",
  ]

  func testIdToToken() throws {
    for (index, token) in tokens.enumerated() {
      let id = ids[index]
      XCTAssertEqual(try hasher.idToToken(id), token)
    }
  }

  func testTokenToId() throws {
    for (index, id) in ids.enumerated() {
      let token = tokens[index]
      XCTAssertEqual(try hasher.tokenToId(token), id)
    }
  }
}
