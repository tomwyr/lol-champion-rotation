import Vapor

struct ImageUrlProvider {
  let b2ApiClient: B2ApiClient
  let cache: Cache?
  let fingerprint: Fingerprint

  func champions(with championIds: [String]) async throws -> [String] {
    let accountToken = try await getAccountToken()
    let downloadToken = try await getDownloadToken(accountToken: accountToken)
    return championIds.map { championId in
      let fileName = "champions/\(championId).jpg"
      return b2ApiClient.fileUrl(for: fileName, authorizeWith: downloadToken)
    }
  }

  private func getAccountToken() async throws -> String {
    let key = "accountToken"
    let getToken = {
      try await b2ApiClient.authorizeAccount().authorizationToken
    }

    guard let cache = cache else {
      return try await getToken()
    }

    if let cachedToken = try await cache.get(key, as: String.self) {
      return cachedToken
    }
    let freshToken = try await getToken()
    try await cache.set(freshToken, to: key, expiresIn: .hours(12))
    return freshToken
  }

  private func getDownloadToken(accountToken: String) async throws -> String {
    let key = "downloadToken#\(fingerprint.value)"
    let getToken = {
      try await b2ApiClient.getDownloadAuthorization(
        authorizationToken: accountToken,
        fileNamePrefix: "champions/",
        validDuration: .minutes(5)
      ).authorizationToken
    }

    guard let cache = cache else {
      return try await getToken()
    }

    if let cachedToken = try await cache.get(key, as: String.self) {
      return cachedToken
    }
    let freshToken = try await getToken()
    try await cache.set(key, to: freshToken, expiresIn: .minutes(3))
    return freshToken
  }
}
