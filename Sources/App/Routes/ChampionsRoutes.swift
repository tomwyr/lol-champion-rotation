import Vapor

func championsRoutes(_ app: Application, _ deps: Dependencies) {
  let anyUserGuard = AnyUserGuard()
  let mobileUserGuard = deps.mobileUserGuard
  let optionalMobileUserGuard = deps.optionalMobileUserGuard

  app.protected(with: anyUserGuard).grouped("champions") { champions in
    champions.protected(with: optionalMobileUserGuard).get(":riotId") { req in
      try req.auth.require(AnyUserAuth.self)
      let auth = try? req.auth.require(MobileUserAuth.self)
      let riotId = req.parameters.get("riotId")!
      let championsService = deps.championsService(request: req)
      let championDetails = try await championsService.championDetails(
        riotId: riotId,
        userId: auth?.userId
      )
      guard let championDetails else {
        throw Abort(.notFound)
      }
      return championDetails
    }

    champions.protected(with: mobileUserGuard).post(":riotId", "observe") { req in
      let auth = try req.auth.require(MobileUserAuth.self)
      let riotId = req.parameters.get("riotId")!
      let input = try req.content.decode(UpdateObserveChampionInput.self)
      let championsService = deps.championsService(request: req)
      try await championsService.updateObserveChampion(
        riotId: riotId,
        by: auth.userId,
        observing: input.observing
      )
      return HTTPStatus.ok
    }

    champions.protected(with: mobileUserGuard).get("observed") { req in
      let auth = try req.auth.require(MobileUserAuth.self)
      let championsService = deps.championsService(request: req)
      return try await championsService.observedChampions(by: auth.userId)
    }

    champions.get("search") { req in
      try req.auth.require(AnyUserAuth.self)
      guard let championName = req.query[String.self, at: "name"] else {
        throw Abort(.badRequest)
      }
      let championsService = deps.championsService(request: req)
      return try await championsService.searchChampions(championName: championName)
    }
  }
}
