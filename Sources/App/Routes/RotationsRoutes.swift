import Vapor

func rotationsRoutes(_ app: Application, _ deps: Dependencies) {
  let anyUserGuard = AnyUserGuard()
  let mobileUserGuard = deps.mobileUserGuard
  let optionalMobileUserGuard = deps.optionalMobileUserGuard

  app.protected(with: anyUserGuard).grouped("rotations") { rotations in
    rotations.protected(with: optionalMobileUserGuard).get(":slug") { req in
      try req.auth.require(AnyUserAuth.self)
      let auth = try? req.auth.require(MobileUserAuth.self)
      let slug = req.parameters.get("slug")!
      let rotationService = deps.rotationService(request: req)
      let rotation = try await rotationService.rotation(
        slug: slug,
        userId: auth?.userId
      )
      guard let rotation else { throw Abort(.notFound) }
      return rotation
    }

    rotations.protected(with: mobileUserGuard).post(":slug", "observe") { req in
      let auth = try req.auth.require(MobileUserAuth.self)
      let slug = req.parameters.get("slug")!
      let input = try req.content.decode(UpdateObserveRotationInput.self)
      let rotationService = deps.rotationService(request: req)
      let result = try await rotationService.updateObserveRotation(
        slug: slug,
        by: auth.userId,
        observing: input.observing
      )
      return result != nil ? HTTPStatus.ok : HTTPStatus.notFound
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
