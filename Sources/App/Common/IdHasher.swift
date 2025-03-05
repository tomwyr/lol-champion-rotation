import CryptoSwift
import Foundation

protocol IdHasher {
  func idToToken(_ id: String) throws -> String
  func tokenToId(_ token: String) throws -> String
}

enum IdHasherError: Error {
  case invalidToken
}

struct ChaChaIdHasher: IdHasher {
  let secretKey: String
  let nonce: String

  func idToToken(_ id: String) throws -> String {
    try chaCha20Encrypt(value: id)
  }

  func tokenToId(_ token: String) throws -> String {
    guard let id = try chaCha20Decrypt(value: token) else {
      throw IdHasherError.invalidToken
    }
    return id
  }

  private func chaCha20Encrypt(value: String) throws -> String {
    try cipher().encrypt(value.bytes).hex
  }

  private func chaCha20Decrypt(value: String) throws -> String? {
    try cipher().decrypt(Array(hex: value)).string
  }

  private func cipher() throws -> ChaCha20 {
    try ChaCha20(key: secretKey, iv: nonce)
  }
}

extension [UInt8] {
  fileprivate var string: String? {
    String(bytes: self, encoding: .utf8)
  }
}

struct Base62IdHasher: IdHasher {
  let seed: String

  func idToToken(_ id: String) throws -> String {
    Base62.encode(id, seed: seed)
  }

  func tokenToId(_ token: String) throws -> String {
    guard let id = Base62.decode(token, seed: seed) else {
      throw IdHasherError.invalidToken
    }
    return id
  }
}
