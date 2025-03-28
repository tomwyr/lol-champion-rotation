import Vapor

func managementRutes(_ app: Application, _ deps: Dependencies) {
  let managementGuard = ManagementGuard(
    appManagementKey: deps.appConfig.appManagementKey
  )

  app.protected(with: managementGuard).get("data", "refresh") { req in
    try req.auth.require(ManagerAuth.self)
    let rotationService = deps.rotationService(request: req)
    let versionService = deps.versionService(request: req)
    let notificationsService = deps.notificationsService(request: req)
    let versionResult = try await versionService.refreshVersion()
    let rotationResult = try await rotationService.refreshRotation()
    if rotationResult.rotationChanged {
      try? await notificationsService.onRotationChanged()
    }
    return RefreshDataResult(version: versionResult, rotation: rotationResult)
  }
}
