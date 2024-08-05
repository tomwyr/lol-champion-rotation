import Vapor

func routes(_ app: Application) throws {
    app.get("rotation", "current") { req in
        let rotationService = DI.rotationService(database: req.db)
        return try await rotationService.currentRotation()
    }

    app.get("rotation", "refresh") { req in
        let rotationService = DI.rotationService(database: req.db)
        return try await rotationService.refreshRotation()
    }
}
