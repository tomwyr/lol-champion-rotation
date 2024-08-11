import Vapor

func routes(_ app: Application) throws {
    app.get("rotation", "current") { req in
        let rotationService = try DI.rotationService(for: req)
        return try await rotationService.currentRotation()
    }

    app.protected(with: AppManagementAuthorizer()).post("rotation", "refresh") { req in
        let rotationService = try DI.rotationService(for: req, skipCache: true)
        return try await rotationService.refreshRotation()
    }
}
