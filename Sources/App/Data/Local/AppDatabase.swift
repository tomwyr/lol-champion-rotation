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

  func regularRotations(after minDate: Date? = nil) async throws -> [RegularChampionRotationModel] {
    try await runner.run { db in
      var query = RegularChampionRotationModel.query(on: db)
        .sort(\.$observedAt, .descending)
      if let minDate {
        query = query.filter(\.$observedAt > minDate)
      }
      return try await query.all()
    }
  }

  func regularRotationsIds(withChampion championRiotId: String) async throws -> [UUID] {
    try await runner.run { db in
      try await RegularChampionRotationModel.query(on: db)
        .sort(\.$observedAt, .descending)
        .filter(\.$champions, .custom("&&"), [championRiotId])
        .all()
        .compactMap(\.id)
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

  func regularRotation(id: String) async throws -> RegularChampionRotationModel? {
    guard let uuid = try? UUID(unsafe: id) else {
      return nil
    }
    return try await runner.run { db in
      try await RegularChampionRotationModel.query(on: db).filter(\.$id == uuid).first()
    }
  }

  func regularRotations(ids: [String]) async throws -> [RegularChampionRotationModel] {
    let uuids = ids.compactMap { id in
      try? UUID(unsafe: id)
    }
    return try await runner.run { db in
      try await RegularChampionRotationModel.query(on: db)
        .filter(\.$id ~~ uuids)
        .sort(\.$observedAt, .descending)
        .all()
    }
  }

  func findPreviousRegularRotation(before id: String) async throws
    -> RegularChampionRotationModel?
  {
    try await runner.run { db in
      let uuid = try UUID(unsafe: id)
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

  func findNextRegularRotation(after id: String) async throws
    -> RegularChampionRotationModel?
  {
    try await runner.run { db in
      let uuid = try UUID(unsafe: id)
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

  func champions(ids: [String]) async throws -> [ChampionModel] {
    let uuids = try ids.map { try UUID(unsafe: $0) }
    return try await runner.run { db in
      try await ChampionModel.query(on: db)
        .filter(\.$id ~~ uuids)
        .sort(\.$name)
        .all()
    }
  }

  func champions(riotIds: [String]) async throws -> [ChampionModel] {
    try await runner.run { db in
      try await ChampionModel.query(on: db)
        .filter(\.$riotId ~~ riotIds)
        .sort(\.$name)
        .all()
    }
  }

  func filterChampions(name: String) async throws -> [ChampionModel] {
    try await runner.run { db in
      try await ChampionModel.query(on: db)
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
        .filter(\.$champions, .custom("&&"), championRiotIds)
        .first()
    }
  }

  func saveChampionsFillingIds(data: [ChampionModel]) async throws -> [String] {
    let championsByRiotId = try await champions().associatedBy(\.riotId)

    return try await runner.run { db in
      try await db.transaction { db in
        var createdChampionsIds = [String]()
        for model in data {
          if let existing = championsByRiotId[model.riotId] {
            model.id = existing.id
            model.releasedAt = existing.releasedAt
            model.$id.exists = true
            try await model.update(on: db)
          } else {
            model.releasedAt = Date.now.trimTime()
            try await model.create(on: db)
            createdChampionsIds.append(model.riotId)
          }
        }
        return createdChampionsIds
      }
    }
  }

  func countChampionsRotations() async throws
    -> [ChampionRotationsCountModel]
  {
    let query: SQLQueryString = """
      SELECT riot_id as "champion",
        (SELECT COUNT(*) FROM "regular-champion-rotations" WHERE riot_id = ANY(champions)) AS "presentIn",
        CASE
          WHEN released_at IS NULL THEN NULL
        ELSE
          (SELECT COUNT(*) FROM "regular-champion-rotations" WHERE observed_at >= released_at)
        END AS "afterRelease",
        (SELECT COUNT(*) FROM "regular-champion-rotations") AS "total"
      FROM "champions"
      """

    return try await runner.runSql { db in
      try await db.raw(query).all(decoding: ChampionRotationsCountModel.self)
    }
  }

  func championStreak(of championRiotId: String) async throws -> ChampionStreakModel? {
    let query: SQLQueryString = """
      WITH 
        champion_release_date AS (
          SELECT released_at FROM "champions" WHERE riot_id = \(bind: championRiotId)
        ),
        rotations_after_release AS (
          SELECT * FROM "regular-champion-rotations"
          WHERE observed_at >= (SELECT released_at FROM champion_release_date)
        ),
        latest_rotation_with_champion AS (
          SELECT observed_at
          FROM rotations_after_release
          WHERE \(bind: championRiotId) = ANY(champions)
          ORDER BY "observed_at" DESC
          LIMIT 1
        ),
        champion_absent_streak AS (
          SELECT COUNT(*) AS count
          FROM rotations_after_release
          WHERE observed_at > COALESCE((SELECT observed_at FROM latest_rotation_with_champion),
                                       (SELECT released_at FROM champion_release_date))
        ),
        latest_rotation_without_champion AS (
          SELECT observed_at
          FROM rotations_after_release
          WHERE NOT \(bind: championRiotId) = ANY(champions)
          ORDER BY "observed_at" DESC
          LIMIT 1
        ),
        champion_present_streak AS (
          SELECT COUNT(*) AS count
          FROM rotations_after_release
          WHERE observed_at > COALESCE((SELECT observed_at FROM latest_rotation_without_champion),
                                       (SELECT released_at FROM champion_release_date))
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
  func getNotificationsConfig(userId: String) async throws -> NotificationsConfigModel? {
    try await runner.run { db in
      try await NotificationsConfigModel.query(on: db).filter(\.$userId == userId).first()
    }
  }

  func updateNotificationsConfig(data: NotificationsConfigModel) async throws {
    try await runner.run { db in
      try await data.save(on: db)
    }
  }

  func removeNotificationsConfigs(userIds: [String]) async throws {
    try await runner.run { db in
      try await NotificationsConfigModel.query(on: db).filter(\.$userId ~~ userIds).delete()
    }
  }

  func getRotationChangedNotificationConfigs() async throws -> [NotificationsConfigModel] {
    try await runner.run { db in
      try await NotificationsConfigModel.query(on: db).filter(\.$rotationChanged == true).all()
    }
  }

  func getChampionsAvailableNotificationConfigs() async throws -> [NotificationsConfigModel] {
    try await runner.run { db in
      try await NotificationsConfigModel.query(on: db).filter(\.$championsAvailable == true).all()
    }
  }
}

extension AppDatabase {
  func userWatchlists(userId: String) async throws
    -> UserWatchlistsModel
  {
    try await runner.run { db in
      if let existing = try await UserWatchlistsModel.query(on: db)
        .filter(\.$userId == userId)
        .first()
      {
        return existing
      }
      let created = UserWatchlistsModel(userId: userId)
      try await created.create(on: db)
      return created
    }
  }

  func userWatchlists(userIds: [String]) async throws -> [UserWatchlistsModel] {
    try await runner.run { db in
      try await UserWatchlistsModel.query(on: db)
        .filter(\.$userId ~~ userIds)
        .all()
    }
  }

  func saveUserWatchlists(data: UserWatchlistsModel) async throws {
    try await runner.run { db in
      try await data.save(on: db)
    }
  }
}
