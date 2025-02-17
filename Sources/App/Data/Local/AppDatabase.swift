import Fluent
import Foundation

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

  func regularRotation(rotationId: String) async throws -> RegularChampionRotationModel? {
    let uuid = try UUID(unsafe: rotationId)
    return try await runner.run { db in
      try await RegularChampionRotationModel.query(on: db).filter(\.$id == uuid).first()
    }
  }

  func findPreviousRegularRotation(before rotationId: String) async throws
    -> RegularChampionRotationModel?
  {
    try await runner.run { db in
      let uuid = try UUID(unsafe: rotationId)
      let nextRotation = try await RegularChampionRotationModel.query(on: db)
        .filter(\.$id == uuid)
        .field(\.$observedAt)
        .first()

      guard let nextDate = nextRotation?.observedAt else {
        return nil
      }

      return try await RegularChampionRotationModel.query(on: db)
        .sort(\.$observedAt, .descending)
        .filter(\.$observedAt < nextDate)
        .first()
    }
  }

  func findNextRegularRotation(after rotationId: String) async throws
    -> RegularChampionRotationModel?
  {
    try await runner.run { db in
      let uuid = try UUID(unsafe: rotationId)
      let previousRotation = try await RegularChampionRotationModel.query(on: db)
        .filter(\.$id == uuid)
        .field(\.$observedAt)
        .first()

      guard let previousDate = previousRotation?.observedAt else {
        return nil
      }

      return try await RegularChampionRotationModel.query(on: db)
        .sort(\.$observedAt, .ascending)
        .filter(\.$observedAt > previousDate)
        .first()
    }
  }

  func champions() async throws -> [ChampionModel] {
    try await runner.run { db in
      try await ChampionModel.query(on: db).all()
    }
  }

  func filterChampions(name: String) async throws -> [ChampionModel] {
    try await runner.run { db in
      try await ChampionModel.query(on: db)
        // PSQL specific ILIKE operator.
        .filter(\.$name, .custom("ilike"), "%\(name)%")
        .all()
    }
  }

  func filterRegularRotations(withChampions championRiotIds: [String]) async throws
    -> [RegularChampionRotationModel]
  {
    try await runner.run { db in
      try await RegularChampionRotationModel.query(on: db)
        // PSQL specific && operator.
        .filter(\.$champions, .custom("&&"), championRiotIds)
        .all()
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

  func patchVersion(olderThan: Date) async throws -> PatchVersionModel? {
    try await runner.run { db in
      try await PatchVersionModel.query(on: db)
        .sort(\.$observedAt, .descending)
        .filter(\.$observedAt < olderThan).first()
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
