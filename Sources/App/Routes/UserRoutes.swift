import Vapor

func userRoutes(_ app: Application, _ deps: Dependencies) {
  let mobileUserGuard = deps.mobileUserGuard

  app.protected(with: mobileUserGuard).get("user") { req in
    let auth = try req.auth.require(MobileUserAuth.self)
    let notificationsService = deps.notificationsService(request: req)
    let settings = try await notificationsService.getSettings(userId: auth.userId)
    return MobileUser(notificationsStatus: .init(from: settings))
  }
}
