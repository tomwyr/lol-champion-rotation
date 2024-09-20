import Vapor

func apiRoutes(_ app: Application, _ deps: Dependencies) throws {
    let userGuard = UserGuard()
    let managementGuard = ManagementGuard(
        appManagementKey: deps.appConfig.appManagementKey
    )

    app.grouped("api") { api in
        api.protected(with: userGuard).get("rotation", "current") { req in
            let user = try req.auth.require(User.self)
            let rotationService = deps.rotationService(request: req)
            return try await rotationService.currentRotation()
        }

        api.protected(with: managementGuard).post("rotation", "refresh") { req in
            try req.auth.require(Manager.self)
            let rotationService = deps.rotationService(request: req, fingerprint: nil)
            return try await rotationService.refreshRotation()
        }
    }
}
