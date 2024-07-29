import Vapor

func routes(_ app: Application) throws {
    let rotationService = DI.rotationService

    app.get("rotation", "current") { req in
        try await rotationService.currentRotation()
    }
}
