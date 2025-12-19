import Vapor

func managementRoutes(_ app: Application, _ deps: Dependencies) {
  let managementGuard = ManagementGuard(
    appManagementKey: deps.appConfig.appManagementKey
  )

  app.protected(with: managementGuard).get("data", "refresh") { req in
    let logger = req.logger
    try req.auth.require(ManagerAuth.self)

    logger.refreshingData()
    let rotationService = deps.rotationService(request: req)
    let versionService = deps.versionService(request: req)
    let notificationsService = deps.notificationsService(request: req)

    logger.refreshingVersion()
    let versionResult = try await versionService.refreshVersion()

    logger.refreshingRotation()
    let rotationResult = try await rotationService.refreshRotation()

    if rotationResult.rotationChanged {
      logger.notifyingRotationChanged()
      do {
        try await notificationsService.onRotationChanged()
      } catch {
        logger.notifyingRotationChangedFailed(cause: error)
      }
    }

    if !rotationResult.championsAdded.isEmpty {
      logger.notifyingChampionsAdded()
      do {
        try await notificationsService.onChampionsAdded(
          championIds: rotationResult.championsAdded,
        )
      } catch {
        logger.notifyingChampionsAddedFailed(cause: error)
      }
    }

    logger.dataRefreshed()
    return RefreshDataResult(version: versionResult, rotation: rotationResult)
  }
}

extension Logger {
  fileprivate func refreshingData() {
    info("Starting full data refresh")
  }

  fileprivate func refreshingVersion() {
    info("Refreshing version data")
  }

  fileprivate func refreshingRotation() {
    info("Refreshing champion rotation")
  }

  fileprivate func notifyingRotationChanged() {
    info("Rotation changed, sending notifications")
  }

  fileprivate func notifyingRotationChangedFailed(cause: any Error) {
    warning("Failed to notify rotation changed: \(cause)")
  }

  fileprivate func notifyingChampionsAdded() {
    info("New champions added, sending notifications")
  }

  fileprivate func notifyingChampionsAddedFailed(cause: any Error) {
    warning("Failed to notify champions added: \(cause)")
  }

  fileprivate func dataRefreshed() {
    info("Data refresh complete")
  }
}
