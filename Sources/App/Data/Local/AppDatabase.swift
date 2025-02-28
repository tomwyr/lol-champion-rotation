import Fluent
import FluentSQL
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

  func currentRegularRotation() async throws -> RegularChampionRotationModel? {
    try await runner.run { db in
      try await RegularChampionRotationModel.query(on: db).sort(\.$observedAt, .descending).first()
    }
  }

  func currentBeginnerRotation() async throws -> BeginnerChampionRotationModel? {
    try await runner.run { db in
      try await BeginnerChampionRotationModel.query(on: db).sort(\.$observedAt, .descending).first()
    }
  }

  func mostRecentRegularRotation(withChampion championRiotId: String) async throws
    -> RegularChampionRotationModel?
  {
    try await runner.run { db in
      try await RegularChampionRotationModel.query(on: db)
        .sort(\.$observedAt, .descending)
        .filter(\.$champions, .custom("&&"), [championRiotId])
        .first()
    }
  }

  func mostRecentBeginnerRotation(withChampion championRiotId: String) async throws
    -> BeginnerChampionRotationModel?
  {
    try await runner.run { db in
      try await BeginnerChampionRotationModel.query(on: db)
        .sort(\.$observedAt, .descending)
        .filter(\.$champions, .custom("&&"), [championRiotId])
        .first()
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

  func champion(id: String) async throws -> ChampionModel? {
    let uuid = try UUID(unsafe: id)
    return try await runner.run { db in
      try await ChampionModel.query(on: db).filter(\.$id == uuid).first()
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
        .sort(\.$name)
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
        .sort(\.$observedAt, .descending)
        .all()
    }
  }

  func filterMostRecentBeginnerRotation(withChampions championRiotIds: [String]) async throws
    -> BeginnerChampionRotationModel?
  {
    try await runner.run { db in
      try await BeginnerChampionRotationModel.query(on: db)
        .sort(\.$observedAt, .descending)
        .limit(1)
        // PSQL specific && operator.
        .filter(\.$champions, .custom("&&"), championRiotIds)
        .first()
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

  func countChampionsOccurrences(of championRiotId: String) async throws
    -> [ChampionsOccurrencesModel]
  {
    let query: SQLQueryString = """
      WITH
        champions_list AS (
          SELECT UNNEST(champions) as champion
          FROM "regular-champion-rotations"
        ),
        champions_ranks AS (
          SELECT champion, COUNT(*) as count
          FROM champions_list
          GROUP BY champion
        )
      SELECT count, ARRAY_AGG(champion) as champions FROM champions_ranks
      GROUP BY count
      ORDER BY count DESC
      """

    return try await runner.runSql { db in
      try await db.raw(query).all(decoding: ChampionsOccurrencesModel.self)
    }
  }

  func championStreak(of championRiotId: String) async throws -> ChampionStreakModel? {
    let query: SQLQueryString = """
      WITH 
        latest_rotation_with_champion AS (
          SELECT observed_at
          FROM "regular-champion-rotations"
          WHERE \(bind: championRiotId) = ANY(champions)
          ORDER BY "observed_at" DESC
          LIMIT 1
        ),
        champion_absent_streak AS (
          SELECT COUNT(*) AS count
          FROM "regular-champion-rotations"
          WHERE observed_at > (SELECT observed_at FROM latest_rotation_with_champion)
        ),
        latest_rotation_without_champion AS (
          SELECT observed_at
          FROM "regular-champion-rotations"
          WHERE NOT \(bind: championRiotId) = ANY(champions)
          ORDER BY "observed_at" DESC
          LIMIT 1
        ),
        champion_present_streak AS (
          SELECT COUNT(*) AS count
          FROM "regular-champion-rotations"
          WHERE observed_at > (SELECT observed_at FROM latest_rotation_without_champion)
        )
      SELECT \(bind: championRiotId) as champion, present_streak.count AS present, absent_streak.count AS absent
      FROM champion_present_streak present_streak, champion_absent_streak absent_streak;
      """

    return try await runner.runSql { db in
      try await db.raw(query).first(decoding: ChampionStreakModel.self)
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
