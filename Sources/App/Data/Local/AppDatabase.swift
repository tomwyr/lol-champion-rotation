import Fluent

struct AppDatabase {
  let runner: DatabaseRunner
}

extension AppDatabase {
  func addRegularRotation(data: RegularChampionRotationModel) async throws {
    try await runner.run { db in
      try await data.create(on: db)
    }
  }
  func addBeginnerRotation(data: BeginnerChampionRotationModel) async throws {
    try await runner.run { db in
      try await data.create(on: db)
    }
  }

  func mostRecentRegularRotation() async throws -> RegularChampionRotationModel? {
    try await runner.run { db in
      try await RegularChampionRotationModel.query(on: db).sort(\.$observedAt, .descending).first()
    }
  }

  func mostRecentBeginnerRotation() async throws -> BeginnerChampionRotationModel? {
    try await runner.run { db in
      try await BeginnerChampionRotationModel.query(on: db).sort(\.$observedAt, .descending).first()
    }
  }

  func champions() async throws -> [ChampionModel] {
    try await runner.run { db in
      try await ChampionModel.query(on: db).all()
    }
  }

  func saveChampionsFillingIds(data: [ChampionModel]) async throws {
    let championsByRiotId = try await champions().associateBy(\.riotId)

    try await runner.run { db in
      try await db.transaction { db in
        for model in data {
          if let existingId = championsByRiotId[model.riotId]?.id {
            model.id = existingId
            model.$id.exists = true
            try await model.update(on: db)
          } else {
            try await model.create(on: db)
          }
        }
      }
    }
  }
}

extension AppDatabase {
  func latestPatchVersion() async throws -> PatchVersionModel? {
    try await runner.run { db in
      try await PatchVersionModel.query(on: db).sort(\.$observedAt, .descending).first()
    }
  }

  func savePatchVersion(data: PatchVersionModel) async throws {
    try await runner.run { db in
      try await data.create(on: db)
    }
  }
}

extension AppDatabase {
  func getNotificationsConfig(deviceId: String) async throws -> NotificationsConfigModel? {
    try await runner.run { db in
      try await NotificationsConfigModel.query(on: db).filter(\.$deviceId == deviceId).first()
    }
  }

  func updateNotificationsConfig(data: NotificationsConfigModel) async throws {
    try await runner.run { db in
      try await data.save(on: db)
    }
  }

  func removeNotificationsConfigs(deviceIds: [String]) async throws {
    try await runner.run { db in
      try await NotificationsConfigModel.query(on: db).filter(\.$deviceId ~~ deviceIds).delete()
    }
  }

  func getEnabledNotificationConfigs() async throws -> [NotificationsConfigModel] {
    try await runner.run { db in
      try await NotificationsConfigModel.query(on: db).filter(\.$enabled == true).all()
    }
  }
}
