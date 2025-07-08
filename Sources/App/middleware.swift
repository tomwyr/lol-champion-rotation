import Vapor

struct ManagementGuard: RequestAuthenticatorGuard {
  let appManagementKey: String

  func authenticate(request: Request) throws -> Authenticatable? {
    let token = request.headers.bearerAuthorization?.token
    guard token == appManagementKey else {
      throw Abort(.unauthorized, reason: "Invalid auth token")
    }
    return ManagerAuth()
  }
}

struct AnyUserGuard: RequestAuthenticatorGuard {
  func authenticate(request: Request) -> Authenticatable? {
    return AnyUserAuth()
  }
}

struct MobileUserGuard: RequestAuthenticatorGuard {
  func authenticate(request: Request) async throws -> Authenticatable? {
    let token = try await request.jwt.firebaseAuth.verify()
    return MobileUserAuth(userId: token.userID)
  }
}

struct OptionalMobileUserGuard: RequestAuthenticatorGuard {
  func authenticate(request: Request) async throws -> Authenticatable? {
    if request.headers.bearerAuthorization != nil,
      let token = try? await request.jwt.firebaseAuth.verify()
    {
      MobileUserAuth(userId: token.userID)
    } else {
      nil
    }
  }
}

protocol RequestAuthenticatorGuard: RequestAuthenticator {
  func authenticate(request: Request) async throws -> Authenticatable?
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
