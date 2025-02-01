import CryptoSwift
import Foundation

struct IdHasher {
  let secretKey: String
  let nonce: String

  func idToToken(_ id: String) throws -> String {
    try chaCha20Encrypt(value: id)
  }

  func tokenToId(_ token: String) throws -> String {
    try chaCha20Decrypt(value: token)
  }

  private func chaCha20Encrypt(value: String) throws -> String {
    try cipher().encrypt(value.bytes).hex
  }

  private func chaCha20Decrypt(value: String) throws -> String {
    try cipher().decrypt(Array(hex: value)).string
  }

  private func cipher() throws -> ChaCha20 {
    try ChaCha20(key: secretKey, iv: nonce)
  }
}

extension [UInt8] {
  var string: String {
    String(bytes: self, encoding: .utf8)!
  }
}
