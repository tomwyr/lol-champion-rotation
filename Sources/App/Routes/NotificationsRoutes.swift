import Vapor

func notificationsRoutes(_ app: Application, _ deps: Dependencies) {
  let mobileUserGuard = deps.mobileUserGuard

  app.protected(with: mobileUserGuard).grouped("notifications") { notifications in
    notifications.put("token") { req in
      let auth = try req.auth.require(MobileUserAuth.self)
      let input = try req.content.decode(NotificationsTokenInput.self)
      let notificationsService = deps.notificationsService(request: req)
      try await notificationsService.updateToken(userId: auth.userId, input: input)
      return Response(status: .noContent)
    }

    notifications.get("settings") { req in
      let auth = try req.auth.require(MobileUserAuth.self)
      let notificationsService = deps.notificationsService(request: req)
      let settings = try await notificationsService.getSettings(userId: auth.userId)
      guard let settings else { throw Abort(.notFound) }
      return settings
    }

    notifications.put("settings") { req in
      let auth = try req.auth.require(MobileUserAuth.self)
      let input = try req.content.decode(NotificationsSettings.self)
      let notificationsService = deps.notificationsService(request: req)
      try await notificationsService.updateSettings(userId: auth.userId, input: input)
      return Response(status: .noContent)
    }
  }
}
