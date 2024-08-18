import Crypto
import Vapor

struct Manager: Authenticatable {}

struct User: Authenticatable {
  let fingerprint: Fingerprint
}

struct Fingerprint {
  let value: String

  init(of request: Request) throws(FingerprintError) {
    let sessionKey = request.headers["X-Session-Key"].first
    let userAgent = request.headers["User-Agent"].first

    guard let sessionKey, let userAgent else {
      throw .insufficientData
    }
    guard UUID(uuidString: sessionKey) != nil else {
      throw .invalidSessionKey
    }

    let baseString = "\(sessionKey)_\(userAgent)"
    self.value = SHA256.hash(data: Data(baseString.utf8)).hex
  }
}

enum FingerprintError: Error {
  case insufficientData, invalidSessionKey
}
