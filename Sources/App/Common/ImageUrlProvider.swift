import Vapor

struct ImageUrlProvider {
  let b2ApiClient: B2ApiClient
  let cache: Cache

  func champions(with championIds: [String]) async throws -> [String] {
    let accountToken = try await getAccountToken()
    let downloadToken = try await getDownloadToken(accountToken: accountToken)
    return championIds.map { championId in
      let fileName = "champions/\(championId).jpg"
      return b2ApiClient.fileUrl(for: fileName, authorizeWith: downloadToken)
    }
  }

  private func getAccountToken() async throws -> String {
    if let cachedToken = try await cache.get("accountToken", as: String.self) {
      return cachedToken
    }
    let freshToken = try await b2ApiClient.authorizeAccount().authorizationToken
    try await cache.set(freshToken, to: "accountToken", expiresIn: .hours(23))
    return freshToken
  }

  private func getDownloadToken(accountToken: String) async throws -> String {
    try await b2ApiClient.getDownloadAuthorization(
      authorizationToken: accountToken,
      fileNamePrefix: "champions/",
      validDurationInSeconds: 60
    ).authorizationToken
  }
}
