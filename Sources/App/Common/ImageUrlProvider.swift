import Vapor

struct ImageUrlProvider {
  let b2ApiClient: B2ApiClient
  let cache: Cache
  let fingerprint: Fingerprint?

  func champions(with championIds: [String]) async throws -> [String] {
    return championIds.map { championId in
      let fileName = "champions/\(championId).jpg"
      return b2ApiClient.fileUrl(for: fileName)
    }
  }

  private func getDownloadToken() async throws -> String {
    let accountToken = try await getAccountToken()
    let downloadToken = try await getDownloadToken(accountToken: accountToken)
    return downloadToken
  }

  private func getAccountToken() async throws -> String {
    let getToken = {
      try await b2ApiClient.authorizeAccount().authorizationToken
    }

    let key = "accountToken"
    if let cachedToken = try await cache.get(key, as: String.self) {
      return cachedToken
    }
    let freshToken = try await getToken()
    try await cache.set(freshToken, to: key, expiresIn: .hours(12))
    return freshToken
  }

  private func getDownloadToken(accountToken: String) async throws -> String {
    let getToken = {
      try await b2ApiClient.getDownloadAuthorization(
        authorizationToken: accountToken,
        fileNamePrefix: "champions/",
        validDuration: .minutes(5)
      ).authorizationToken
    }

    guard let fingerprint = fingerprint else {
      return try await getToken()
    }

    let key = "downloadToken#\(fingerprint.value)"
    if let cachedToken = try await cache.get(key, as: String.self) {
      return cachedToken
    }
    let freshToken = try await getToken()
    try await cache.set(key, to: freshToken, expiresIn: .minutes(3))
    return freshToken
  }
}
