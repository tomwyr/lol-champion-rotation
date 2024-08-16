import Vapor

func routes(_ app: Application, _ deps: Dependencies) throws {
    let userGuard = UserGuard()
    let managementGuard = ManagementGuard(
        appManagementKey: deps.appConfig.appManagementKey
    )

    app.protected(with: userGuard).get("rotation", "current") { req in
        let user = try req.auth.require(User.self)
        let rotationService = try DI.rotationService(for: req, fingerprint: user.fingerprint)
        return try await rotationService.currentRotation()
    }

    app.protected(with: managementGuard).post("rotation", "refresh") { req in
        try req.auth.require(Manager.self)
        let rotationService = try deps.rotationService(request: req, fingerprint: nil)
        return try await rotationService.refreshRotation()
    }
}
