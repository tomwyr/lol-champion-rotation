import Vapor

func routes(_ app: Application, _ deps: Dependencies) throws {
  let userGuard = UserGuard()
  let managementGuard = ManagementGuard(
    appManagementKey: deps.appConfig.appManagementKey
  )

  app.grouped("api") { api in
    api.protected(with: userGuard).get("rotation", "current") { req in
      try req.auth.require(User.self)
      let rotationService = deps.rotationService(request: req)
      return try await rotationService.currentRotation()
    }

    api.protected(with: userGuard).put("notifications", "token") { req in
      try req.auth.require(User.self)
      let input = try req.content.decode(NotificationsTokenInput.self)
      let notificationsService = deps.notificationsService(request: req)
      try await notificationsService.updateToken(input: input)
      return Response(status: .noContent)
    }

    api.protected(with: userGuard).put("notifications", "settings") { req in
      try req.auth.require(User.self)
      let input = try req.content.decode(NotificationsSettingsInput.self)
      let notificationsService = deps.notificationsService(request: req)
      try await notificationsService.updateSettings(input: input)
      return Response(status: .noContent)
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
