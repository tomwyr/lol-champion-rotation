import XCTest

@testable import App

extension Dependencies {
  static func mock(
    appConfig: AppConfig = .empty(),
    httpClient: HttpClient = MockHttpClient(respond: { _ in nil })
  ) -> Dependencies {
    .init(
      appConfig: appConfig,
      httpClient: httpClient
    )
  }
}

extension AppConfig {
  static func empty(
    databaseUrl: String = "",
    appAllowedOrigins: [String] = [],
    appManagementKey: String = "",
    b2AppKeyId: String = "",
    b2AppKeySecret: String = "",
    riotApiKey: String = "",
    idHasherSeed: String = ""
  ) -> AppConfig {
    .init(
      databaseUrl: databaseUrl,
      appAllowedOrigins: appAllowedOrigins,
      appManagementKey: appManagementKey,
      b2AppKeyId: b2AppKeyId,
      b2AppKeySecret: b2AppKeySecret,
      riotApiKey: riotApiKey,
      idHasherSeed: idHasherSeed
    )
  }
}

typealias HttpRespond = @Sendable (String) -> Any?

final class MockHttpClient: HttpClient, @unchecked Sendable {
  private(set) var requestedUrls: [String] = []

  private let respond: HttpRespond

  init(respond: @escaping HttpRespond = { _ in nil }) {
    self.respond = respond
  }

  func get<T>(
    from url: String,
    into type: T.Type,
    with headers: [String: String]
  ) async throws -> T where T: Decodable {
    request(url)
  }

  func post<T>(
    to url: String,
    into type: T.Type,
    with headers: [String: String],
    sending body: [String: any Encodable]
  ) async throws -> T where T: Decodable {
    request(url)
  }

  private func request<T>(_ url: String) -> T {
    requestedUrls.append(url)

    guard let response = respond(url) ?? respondDefault(url) else {
      fatalError("Response of type \(T.self) for request url \(url) not found")
    }
    guard let response = (response as? T) else {
      fatalError("Response for request url \(url) is not of expected type \(T.self)")
    }
    return response
  }
}
