import Vapor

struct AppManagementAuthorizer: RequestAuthorizer {
  private let appManagementKey = Environment.get("APP_MANAGEMENT_KEY")!

  func authorize(request: Request) -> Error? {
    let token = request.headers.bearerAuthorization?.token
    guard token == appManagementKey else {
      return Abort(.unauthorized, reason: "Invalid auth token")
    }
    return nil
  }
}

protocol RequestAuthorizer: Middleware {
  func authorize(request: Request) -> Error?
}

extension RequestAuthorizer {
  func respond(to request: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
    if let error = authorize(request: request) {
      request.eventLoop.makeFailedFuture(error)
    } else {
      next.respond(to: request)
    }
  }
}
