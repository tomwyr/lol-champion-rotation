import Testing

@testable import App

@Suite struct ChaChaIdHasherTests {
  let hasher = ChaChaIdHasher(
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
    "b0bdb5240a3994c8c73763ee539d60625ebde7bc37d2a6db7e0ad92894289cb3d6921c84",
    "b1bbbf230a6a9fcbc73260ba009d60655cede7bd3482a2db795d8e28c3279fb587c54f8f",
    "b6bfe2240f6ac8c8c76e61e3019d60625cefe7bc3e87f4db7c5f8d2f90249ae6d6c749de",
    "b7bfb322006c9ccfc76734ba5d9d606108bee7bc3e80ffdb2d5ddd2bc275cdb4dac61d84",
    "b7e9b7205a3e99cdc76165ed509d603f5deee7e53382f5db7d5b8e7f902598e681c24dd9",
  ]

  @Test func idToToken() throws {
    for (index, token) in tokens.enumerated() {
      let id = ids[index]
      #expect(try hasher.idToToken(id) == token)
    }
  }

  @Test func tokenToId() throws {
    for (index, id) in ids.enumerated() {
      let token = tokens[index]
      #expect(try hasher.tokenToId(token) == id)
    }
  }
}

@Suite struct Base62IdHasherTests {
  let hasher = Base62IdHasher(
    seed: "a1m4vz1bu9a3ttn4kflvrjy29bw1yol5"
  )

  let ids = [
    "71343685-a356-4e3a-816a-affb29575bb8",
    "67933e36-d0ae-4b11-92fe-f11be661d513",
    "13d46ed5-818d-4e13-88c3-c32e653b577b",
    "03529c02-1da8-4feb-88d8-21baddd096c8",
    "0e10c150-7565-4802-a5f2-b715641bb23e",
  ]

  let tokens = [
    "VeJnzKMrmTu0UN6JWiIVkqFIydEG6A3oKRqAVuU4UXtPtDIQ",
    "a5nKTh47nSTgnZ5BTNS0WKCz94rd8szZT8IFJKGMMDyy2Igy",
    "ij4hLmq0ygGkvFGKBaAsi9BsTkpkVnmFe5kvByUrMxgYLYoQ",
    "nglIuf2mXVIwqeaSKPXW0JM9IOLIj1E4P9eZ5PhYEHvVfMqX",
    "nSHKYty2TKGAQRIFAdoEPlSxsEtIJUGgafLZ6a8Cm8bEoZDS",
  ]

  @Test func idToToken() throws {
    for (index, token) in tokens.enumerated() {
      let id = ids[index]
      #expect(try hasher.idToToken(id) == token)
    }
  }

  @Test func tokenToId() throws {
    for (index, id) in ids.enumerated() {
      let token = tokens[index]
      #expect(try hasher.tokenToId(token) == id)
    }
  }
}
