import Vapor

func routes(_ app: Application, _ deps: Dependencies) throws {
  let userGuard = UserGuard()
  let mobileUserGuard = MobileUserGuard()
  let managementGuard = ManagementGuard(
    appManagementKey: deps.appConfig.appManagementKey
  )

  app.protected(with: userGuard).get("rotation", "current") { req in
    try req.auth.require(UserAuth.self)
    let rotationService = deps.rotationService(request: req)
    return try await rotationService.currentRotation()
  }

  app.protected(with: userGuard).get("rotation") { req in
    try req.auth.require(UserAuth.self)
    guard let nextRotationToken = req.query[String.self, at: "nextRotationToken"] else {
      throw Abort(.badRequest)
    }
    let rotationService = deps.rotationService(request: req)
    let rotation = try await rotationService.rotation(nextRotationToken: nextRotationToken)
    guard let rotation else { throw Abort(.notFound) }
    return rotation
  }

  app.protected(with: mobileUserGuard).get("user") { req in
    let auth = try req.auth.require(MobileUserAuth.self)
    let notificationsService = deps.notificationsService(request: req)
    let tokenSynced = try await notificationsService.hasSettings(deviceId: auth.deviceId)
    return MobileUser(notificationsTokenSynced: tokenSynced)
  }

  app.protected(with: mobileUserGuard).grouped("notifications") { routes in
    routes.put("token") { req in
      let auth = try req.auth.require(MobileUserAuth.self)
      let input = try req.content.decode(NotificationsTokenInput.self)
      let notificationsService = deps.notificationsService(request: req)
      try await notificationsService.updateToken(deviceId: auth.deviceId, input: input)
      return Response(status: .noContent)
    }

    routes.get("settings") { req in
      let auth = try req.auth.require(MobileUserAuth.self)
      let notificationsService = deps.notificationsService(request: req)
      let settings = try await notificationsService.getSettings(deviceId: auth.deviceId)
      guard let settings else { throw Abort(.notFound) }
      return settings
    }

    routes.put("settings") { req in
      let auth = try req.auth.require(MobileUserAuth.self)
      let input = try req.content.decode(NotificationsSettings.self)
      let notificationsService = deps.notificationsService(request: req)
      try await notificationsService.updateSettings(deviceId: auth.deviceId, input: input)
      return Response(status: .noContent)
    }
  }

  app.protected(with: managementGuard).get("data", "refresh") { req in
    try req.auth.require(ManagerAuth.self)
    let rotationService = deps.rotationService(request: req)
    let versionService = deps.versionService(request: req)
    let versionResult = try await versionService.refreshVersion()
    let rotationResult = try await rotationService.refreshRotation()
    return RefreshDataResult(version: versionResult, rotation: rotationResult)
  }
}
