import Vapor

struct ManagementGuard: RequestAuthenticatorGuard {
  let managementApiKey: String

  func authenticate(request: Request) throws -> ManagerUserAuth? {
    let token = request.headers.bearerAuthorization?.token
    guard let token, token == managementApiKey else {
      throw Abort(.unauthorized, reason: "Invalid auth token")
    }
    return ManagerUserAuth()
  }
}

struct MobileUserGuard: RequestAuthenticatorGuard {
  func authenticate(request: Request) async throws -> MobileUserAuth? {
    let token = try await request.jwt.firebaseAuth.verify()
    return MobileUserAuth(userId: token.userID)
  }
}

struct WebUserGuard: RequestAuthenticatorGuard {
  let webApiKey: String

  func authenticate(request: Request) async throws -> WebUserAuth? {
    let token = request.headers.bearerAuthorization?.token
    guard let token, token == webApiKey else {
      throw Abort(.unauthorized, reason: "Invalid auth token")
    }
    return WebUserAuth()
  }
}

typealias AnyMobileUserGuard = any RequestAuthenticatorGuard<MobileUserAuth>
typealias AnyWebUserGuard = any RequestAuthenticatorGuard<WebUserAuth>

struct AppUserGuard: RequestAuthenticatorGuard {
  let mobileGuard: AnyMobileUserGuard
  let webGuard: AnyWebUserGuard

  func authenticate(request: Request) async throws -> AppUserAuth? {
    if let mobileAuth = try? await mobileGuard.authenticate(request: request) {
      .mobile(mobileAuth)
    } else if let webAuth = try? await webGuard.authenticate(request: request) {
      .web(webAuth)
    } else {
      throw Abort(.unauthorized, reason: "Invalid auth token")
    }
  }
}

protocol RequestAuthenticatorGuard<AuthenticatableType>: RequestAuthenticator {
  associatedtype AuthenticatableType: Authenticatable

  func authenticate(request: Request) async throws -> AuthenticatableType?
}

extension RequestAuthenticatorGuard {
  func authenticate(request: Request) -> EventLoopFuture<Void> {
    request.eventLoop.makeFutureWithTask {
      if let result = try await authenticate(request: request) {
        request.auth.login(result)
      }
    }
  }
}
