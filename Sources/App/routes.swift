import Vapor

func routes(_ app: Application, _ deps: Dependencies) throws {
  let userGuard = UserGuard()
  let mobileUserGuard = MobileUserGuard()
  let managementGuard = ManagementGuard(
    appManagementKey: deps.appConfig.appManagementKey
  )

  app.protected(with: userGuard).grouped("rotation") { rotation in
    rotation.get(":id") { req in
      try req.auth.require(UserAuth.self)
      let rotationId = req.parameters.get("id")!
      let rotationService = deps.rotationService(request: req)
      let rotation = try await rotationService.rotation(rotationId: rotationId)
      guard let rotation else { throw Abort(.notFound) }
      return rotation
    }

    rotation.get("current") { req in
      try req.auth.require(UserAuth.self)
      let rotationService = deps.rotationService(request: req)
      return try await rotationService.currentRotation()
    }

    rotation.get { req in
      try req.auth.require(UserAuth.self)
      guard let nextRotationToken = req.query[String.self, at: "nextRotationToken"] else {
        throw Abort(.badRequest)
      }
      let rotationService = deps.rotationService(request: req)
      let rotation = try await rotationService.nextRotation(nextRotationToken: nextRotationToken)
      guard let rotation else { throw Abort(.notFound) }
      return rotation
    }

    rotation.get("search") { req in
      try req.auth.require(UserAuth.self)
      guard let championName = req.query[String.self, at: "championName"] else {
        throw Abort(.badRequest)
      }
      let rotationService = deps.rotationService(request: req)
      return try await rotationService.filterRotations(by: championName)
    }
  }

  app.protected(with: userGuard).grouped("rotations") { rotation in
    rotation.get(":id") { req in
      try req.auth.require(UserAuth.self)
      let rotationId = req.parameters.get("id")!
      let rotationService = deps.rotationService(request: req)
      let rotation = try await rotationService.rotation(rotationId: rotationId)
      guard let rotation else { throw Abort(.notFound) }
      return rotation
    }

    rotation.get("current") { req in
      try req.auth.require(UserAuth.self)
      let rotationService = deps.rotationService(request: req)
      return try await rotationService.currentRotation()
    }

    rotation.get { req in
      try req.auth.require(UserAuth.self)
      guard let nextRotationToken = req.query[String.self, at: "nextRotationToken"] else {
        throw Abort(.badRequest)
      }
      let rotationService = deps.rotationService(request: req)
      let rotation = try await rotationService.nextRotation(nextRotationToken: nextRotationToken)
      guard let rotation else { throw Abort(.notFound) }
      return rotation
    }

    rotation.get("search") { req in
      try req.auth.require(UserAuth.self)
      guard let championName = req.query[String.self, at: "championName"] else {
        throw Abort(.badRequest)
      }
      let rotationService = deps.rotationService(request: req)
      return try await rotationService.filterRotations(by: championName)
    }
  }

  app.protected(with: userGuard).grouped("champions") { champions in
    champions.get(":id") { req in
      try req.auth.require(UserAuth.self)
      let championId = req.parameters.get("id")!
      let rotationService = deps.championsService(request: req)
      let championDetails = try await rotationService.championDetails(championId: championId)
      guard let championDetails else {
        throw Abort(.notFound)
      }
      return championDetails
    }

    champions.get("search") { req in
      try req.auth.require(UserAuth.self)
      guard let championName = req.query[String.self, at: "name"] else {
        throw Abort(.badRequest)
      }
      let championsService = deps.championsService(request: req)
      return try await championsService.searchChampions(championName: championName)
    }
  }

  app.protected(with: mobileUserGuard).get("user") { req in
    let auth = try req.auth.require(MobileUserAuth.self)
    let notificationsService = deps.notificationsService(request: req)
    let settings = try await notificationsService.getSettings(deviceId: auth.deviceId)
    return MobileUser(notificationsStatus: .init(from: settings))
  }

  app.protected(with: mobileUserGuard).grouped("notifications") { notifications in
    notifications.put("token") { req in
      let auth = try req.auth.require(MobileUserAuth.self)
      let input = try req.content.decode(NotificationsTokenInput.self)
      let notificationsService = deps.notificationsService(request: req)
      try await notificationsService.updateToken(deviceId: auth.deviceId, input: input)
      return Response(status: .noContent)
    }

    notifications.get("settings") { req in
      let auth = try req.auth.require(MobileUserAuth.self)
      let notificationsService = deps.notificationsService(request: req)
      let settings = try await notificationsService.getSettings(deviceId: auth.deviceId)
      guard let settings else { throw Abort(.notFound) }
      return settings
    }

    notifications.put("settings") { req in
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
