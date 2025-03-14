import Vapor

func championsRoutes(_ app: Application, _ deps: Dependencies) {
  let anyUserGuard = AnyUserGuard()

  app.protected(with: anyUserGuard).grouped("champions") { champions in
    champions.get(":id") { req in
      try req.auth.require(AnyUserAuth.self)
      let championId = req.parameters.get("id")!
      let rotationService = deps.championsService(request: req)
      let championDetails = try await rotationService.championDetails(championId: championId)
      guard let championDetails else {
        throw Abort(.notFound)
      }
      return championDetails
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
