import Vapor

func rotationsRoutes(_ app: Application, _ deps: Dependencies) {
  let anyUserGuard = AnyUserGuard()

  app.protected(with: anyUserGuard).grouped("rotations") { rotations in
    rotations.get(":id") { req in
      try req.auth.require(AnyUserAuth.self)
      let rotationId = req.parameters.get("id")!
      let rotationService = deps.rotationService(request: req)
      let rotation = try await rotationService.rotation(rotationId: rotationId)
      guard let rotation else { throw Abort(.notFound) }
      return rotation
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
