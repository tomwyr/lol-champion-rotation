import Vapor

func routes(_ app: Application, _ deps: Dependencies) throws {
  let userGuard = UserGuard()
  let mobileUserGuard = MobileUserGuard()
  let managementGuard = ManagementGuard(
    appManagementKey: deps.appConfig.appManagementKey
  )

  app.grouped("api") { api in
    api.protected(with: userGuard).get("rotation", "current") { req in
      try req.auth.require(User.self)
      let rotationService = deps.rotationService(request: req)
      return try await rotationService.currentRotation()
    }

    api.protected(with: mobileUserGuard).grouped("notifications") { routes in
      routes.put("token") { req in
        let user = try req.auth.require(MobileUser.self)
        let input = try req.content.decode(NotificationsTokenInput.self)
        let notificationsService = deps.notificationsService(request: req)
        try await notificationsService.updateToken(deviceId: user.deviceId, input: input)
        return Response(status: .noContent)
      }

      routes.get("settings") { req in
        let user = try req.auth.require(MobileUser.self)
        let notificationsService = deps.notificationsService(request: req)
        let settings = try await notificationsService.getSettings(deviceId: user.deviceId)
        guard let settings else { throw Abort(.notFound) }
        return settings
      }

      routes.put("settings") { req in
        let user = try req.auth.require(MobileUser.self)
        let input = try req.content.decode(NotificationsSettings.self)
        let notificationsService = deps.notificationsService(request: req)
        try await notificationsService.updateSettings(deviceId: user.deviceId, input: input)
        return Response(status: .noContent)
      }
    }

    api.protected(with: managementGuard).get("data", "refresh") { req in
      try req.auth.require(Manager.self)
      let rotationService = deps.rotationService(request: req)
      let versionService = deps.versionService(request: req)
      let versionResult = try await versionService.refreshVersion()
      let rotationResult = try await rotationService.refreshRotation()
      return RefreshDataResult(version: versionResult, rotation: rotationResult)
    }
  }
}
