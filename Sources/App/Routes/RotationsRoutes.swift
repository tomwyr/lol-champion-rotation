import Vapor

func rotationsRoutes(_ app: Application, _ deps: Dependencies) {
  let anyUserGuard = AnyUserGuard()
  let mobileUserGuard = deps.mobileUserGuard

  app.protected(with: anyUserGuard).grouped("rotations") { rotations in
    rotations.protected(with: mobileUserGuard).get(":id") { req in
      try req.auth.require(AnyUserAuth.self)
      let userId = try? req.auth.require(MobileUserAuth.self).userId
      let rotationId = req.parameters.get("id")!
      let rotationService = deps.rotationService(request: req)
      let rotation = try await rotationService.rotation(rotationId: rotationId, userId: userId)
      guard let rotation else { throw Abort(.notFound) }
      return rotation
    }

    rotations.protected(with: mobileUserGuard).post(":id", "observe") { req in
      let auth = try req.auth.require(MobileUserAuth.self)
      let rotationId = req.parameters.get("id")!
      let input = try req.content.decode(ObserveRotationInput.self)
      let rotationService = deps.rotationService(request: req)
      try await rotationService.updateObserveRotation(
        rotationId: rotationId,
        by: auth.userId,
        observing: input.observing
      )
      return HTTPStatus.ok
    }

    rotations.get("current") { req in
      try req.auth.require(AnyUserAuth.self)
      let rotationService = deps.rotationService(request: req)
      return try await rotationService.currentRotation()
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
