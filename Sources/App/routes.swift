import Vapor

func routes(_ app: Application, _ deps: Dependencies) {
  managementRutes(app, deps)
  championsRoutes(app, deps)
  rotationsRoutes(app, deps)
  notificationsRoutes(app, deps)
  userRoutes(app, deps)
}
