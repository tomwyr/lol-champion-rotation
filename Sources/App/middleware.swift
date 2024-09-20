import Vapor

struct ManagementGuard: RequestAuthenticatorGuard {
  let appManagementKey: String

  func authenticate(request: Request) throws -> Authenticatable {
    let token = request.headers.bearerAuthorization?.token
    guard token == appManagementKey else {
      throw Abort(.unauthorized, reason: "Invalid auth token")
    }
    return Manager()
  }
}

struct UserGuard: RequestAuthenticatorGuard {
  func authenticate(request: Request) throws -> Authenticatable {
    return User()
  }
}

protocol RequestAuthenticatorGuard: RequestAuthenticator {
  func authenticate(request: Request) throws -> Authenticatable
}

extension RequestAuthenticatorGuard {
  func authenticate(request: Request) -> EventLoopFuture<Void> {
    do {
      let result = try authenticate(request: request)
      request.auth.login(result)
      return request.eventLoop.makeSucceededVoidFuture()
    } catch {
      return request.eventLoop.makeFailedFuture(error)
    }
  }
}
