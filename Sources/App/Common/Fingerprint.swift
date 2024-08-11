import Crypto
import Vapor

struct Fingerprint {
  let value: String

  init(of request: Request) throws(FingerprintError) {
    let ipAddress = request.remoteAddress?.description
    let userAgent = request.headers["User-Agent"].first

    guard let ipAddress, let userAgent else {
      throw .insufficientData
    }

    let baseString = "\(ipAddress)_\(userAgent)"
    self.value = SHA256.hash(data: Data(baseString.utf8)).hex
  }
}

enum FingerprintError: Error {
  case insufficientData
}
