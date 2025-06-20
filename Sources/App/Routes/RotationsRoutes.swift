import Vapor

func rotationsRoutes(_ app: Application, _ deps: Dependencies) {
  let anyUserGuard = AnyUserGuard()
  let mobileUserGuard = deps.mobileUserGuard
  let optionalMobileUserGuard = deps.optionalMobileUserGuard

  app.protected(with: anyUserGuard).grouped("rotations") { rotations in
    rotations.protected(with: optionalMobileUserGuard).get(":id") { req in
      try req.auth.require(AnyUserAuth.self)
      let auth = try? req.auth.require(MobileUserAuth.self)
      let rotationId = req.parameters.get("id")!
      let rotationService = deps.rotationService(request: req)
      let rotation = try await rotationService.rotation(
        rotationId: rotationId,
        userId: auth?.userId
      )
      guard let rotation else { throw Abort(.notFound) }
      return rotation
    }

    rotations.protected(with: mobileUserGuard).post(":id", "observe") { req in
      let auth = try req.auth.require(MobileUserAuth.self)
      let rotationId = req.parameters.get("id")!
      let input = try req.content.decode(UpdateObserveRotationInput.self)
      let rotationService = deps.rotationService(request: req)
      try await rotationService.updateObserveRotation(
        rotationId: rotationId,
        by: auth.userId,
        observing: input.observing
      )
      return HTTPStatus.ok
    }

    rotations.protected(with: mobileUserGuard).get("observed") { req in
      let auth = try req.auth.require(MobileUserAuth.self)
      let rotationService = deps.rotationService(request: req)
      return try await rotationService.observedRotations(by: auth.userId)
    }

    rotations.get("overview") { req in
      try req.auth.require(AnyUserAuth.self)
      let rotationService = deps.rotationService(request: req)
      return try await rotationService.rotationsOverview()
    }

    rotations.get("current") { req in
      try req.auth.require(AnyUserAuth.self)
      let rotationService = deps.rotationService(request: req)
      return try await rotationService.currentRegularRotation()
    }

    rotations.get("predict") { req in
      try req.auth.require(AnyUserAuth.self)
      let rotationService = deps.rotationService(request: req)
      return try await rotationService.predictRotation()
    }

    rotations.get { req in
      try req.auth.require(AnyUserAuth.self)
      guard let nextRotationToken = req.query[String.self, at: "nextRotationToken"] else {
        throw Abort(.badRequest)
      }
      let rotationService = deps.rotationService(request: req)
      let rotation = try await rotationService.nextRotation(nextRotationToken: nextRotationToken)
      guard let rotation else { throw Abort(.notFound) }
      return rotation
    }

    rotations.get("search") { req in
      try req.auth.require(AnyUserAuth.self)
      guard let championName = req.query[String.self, at: "championName"] else {
        throw Abort(.badRequest)
      }
      let rotationService = deps.rotationService(request: req)
      return try await rotationService.filterRotations(by: championName)
    }
  }
}
