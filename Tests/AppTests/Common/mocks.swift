import FCM
import Vapor

@testable import App

typealias HttpRespond = @Sendable (String) -> Any?

class MockHttpClient: HttpClient, @unchecked Sendable {
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

typealias GraphQLRespond = @Sendable (String) -> Any?

class MockGraphQLClient: GraphQLClient, @unchecked Sendable {
  private(set) var requestedQueries: [String] = []
  private(set) var requestedVariables: [[String: String]] = []
  private(set) var requestedHeaders: [[String: String]] = []

  private let respond: GraphQLRespond

  init(respond: @escaping GraphQLRespond = { _ in nil }) {
    self.respond = respond
  }

  func execute<T>(
    endpoint: String,
    query: String,
    headers: [String: String],
    variables: [String: String],
    into type: T.Type
  ) async throws -> T where T: Decodable, T: Sendable {
    requestedQueries.append(query)
    requestedVariables.append(variables)
    requestedHeaders.append(headers)

    guard let response = respond(query) ?? respondDefault(query) else {
      fatalError("Response of type \(T.self) for request query not found:\n\(query)")
    }
    guard let response = (response as? T) else {
      fatalError("Response for request query is not of expected type \(T.self):\n\(query)")
    }
    return response
  }
}

typealias SendFcmMessage = @Sendable (FCMMessageDefault) -> String?

final class MockFcmDispatcher: FcmDispatcher, @unchecked Sendable {
  private let sentMessagesQueue = DispatchQueue(label: "MockFcmDispatcher#sentMessages")
  private(set) var sentMessages: [FCMMessageDefault] = []

  let respond: SendFcmMessage

  init(respond: @escaping SendFcmMessage = { _ in nil }) {
    self.respond = respond
  }

  func send(_ message: FCMMessageDefault) async throws -> String {
    sentMessagesQueue.sync {
      sentMessages.append(message)
    }
    guard let result = respond(message) else {
      fatalError("Response for message \(message) not found")
    }
    return result
  }
}

final class SpyRotationForecast: RotationForecast, @unchecked Sendable {
  private(set) var predictCalls = 0
  private let delegate: RotationForecast

  init(delegate: RotationForecast = DefaultRotationForecast()) {
    self.delegate = delegate
  }

  func predict(
    champions: [String], rotations: [[String]],
    refRotationId: String,
  ) throws(App.RotationForecastError) -> [String] {
    predictCalls += 1
    return try delegate.predict(
      champions: champions,
      rotations: rotations,
      refRotationId: refRotationId,
    )
  }
}

struct MockMobileUserGuard: RequestAuthenticatorGuard {
  let userId: String
  let token: String

  init(userId: String = mobileUserId, token: String = mobileToken) {
    self.userId = userId
    self.token = token
  }

  func authenticate(request: Request) throws -> Authenticatable? {
    let authorization = request.headers["Authorization"].first
    guard authorization == "Bearer \(token)" else {
      throw Abort(.unauthorized)
    }
    return MobileUserAuth(userId: userId)
  }
}

struct MockOptionalMobileUserGuard: RequestAuthenticatorGuard {
  let userId: String
  let token: String

  init(userId: String = mobileUserId, token: String = mobileToken) {
    self.userId = userId
    self.token = token
  }

  func authenticate(request: Request) throws -> Authenticatable? {
    let authorization = request.headers["Authorization"].first
    return if authorization == "Bearer \(token)" {
      MobileUserAuth(userId: userId)
    } else {
      nil
    }
  }
}

typealias GetDate = @Sendable () -> Date

struct MockInstant: Instant {
  let getCurrentDate: GetDate?

  init(getCurrentDate: GetDate? = nil) {
    self.getCurrentDate = getCurrentDate
  }

  var now: Date { getCurrentDate?() ?? Date.now }
}
