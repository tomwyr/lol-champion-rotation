import Crypto
import Vapor

enum AppUserAuth: Authenticatable {
  case mobile(MobileUserAuth)
  case web(WebUserAuth)

  var userId: String? {
    switch self {
    case .mobile(let mobile):
      mobile.userId
    case .web:
      nil
    }
  }
}

struct ManagerUserAuth: Authenticatable {}

struct WebUserAuth: Authenticatable {}

struct MobileUserAuth: Authenticatable {
  let userId: String
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
