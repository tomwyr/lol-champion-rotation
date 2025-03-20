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
