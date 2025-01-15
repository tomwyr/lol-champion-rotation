import Fluent

extension Migrations {
  func addAppMigrations() {
    add(InitialSchema())
    add(AddPatchVersions())
    add(AddNotificationConfigs())
    add(SplitChampionRotations())
  }
}

struct InitialSchema: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("champion-rotations")
      .id()
      .field("observed_at", .datetime)
      .field("beginner_max_level", .int)
      .field("beginner_champions", .array(of: .string))
      .field("regular_champions", .array(of: .string))
      .create()

    try await database.schema("champions")
      .id()
      .field("riot_id", .string)
      .field("name", .string)
      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("champion-rotations").delete()
    try await database.schema("champions").delete()
  }
}

struct AddPatchVersions: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("patch-versions")
      .id()
      .field("observed_at", .datetime)
      .field("value", .string)
      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("patch-versions").delete()
  }
}

struct AddNotificationConfigs: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("notifications-configs")
      .id()
      .field("device_id", .string)
      .field("token", .string)
      .field("enabled", .bool)
      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("notifications-configs").delete()
  }
}

struct SplitChampionRotations: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await createRegularRotationsTable(database)
    try await createBeginnerRotationsTable(database)
    try await populateRegularRotations(database)
    try await populateBeginnerRotations(database)
    try await deleteCombinedRotationsTable(database)
  }

  func revert(on database: any Database) async throws {
    try await createCombinedRotationsTable(database)
    try await deleteSplitRotationsTables(database)
  }

  func createRegularRotationsTable(_ db: Database) async throws {
    try await db.schema("regular-champion-rotations")
      .id()
      .field("observed_at", .datetime)
      .field("champions", .array(of: .string))
      .create()
  }

  func createBeginnerRotationsTable(_ db: Database) async throws {
    try await db.schema("beginner-champion-rotations")
      .id()
      .field("observed_at", .datetime)
      .field("max_level", .int)
      .field("champions", .array(of: .string))
      .create()
  }

  func createCombinedRotationsTable(_ db: Database) async throws {
    try await db.schema("champion-rotations")
      .id()
      .field("observed_at", .datetime)
      .field("beginner_max_level", .int)
      .field("beginner_champions", .array(of: .string))
      .field("regular_champions", .array(of: .string))
      .create()
  }

  func populateRegularRotations(_ db: Database) async throws {
    let allRotations = try await ChampionRotationModel.query(on: db).all()

    var regularRotations = [RegularChampionRotationModel]()
    for rotation in allRotations {
      let lastRotation = regularRotations.last
      let nextRotation = rotation.toRegularRotation()
      if lastRotation == nil || !lastRotation!.same(as: nextRotation) {
        regularRotations.append(nextRotation)
      }
    }

    try await regularRotations.create(on: db)
  }

  func populateBeginnerRotations(_ db: Database) async throws {
    let allRotations = try await ChampionRotationModel.query(on: db).all()

    var beginnerRotations = [BeginnerChampionRotationModel]()
    for rotation in allRotations {
      let lastRotation = beginnerRotations.last
      let nextRotation = rotation.toBeginnerRotation()
      if lastRotation == nil || !lastRotation!.same(as: nextRotation) {
        beginnerRotations.append(nextRotation)
      }
    }

    try await beginnerRotations.create(on: db)
  }

  func deleteCombinedRotationsTable(_ db: Database) async throws {
    try await db.schema("champion-rotations").delete()
  }

  func deleteSplitRotationsTables(_ db: Database) async throws {
    try await db.schema("regular-champion-rotations").delete()
    try await db.schema("beginner-champion-rotations").delete()
  }
}

extension ChampionRotationModel {
  func toRegularRotation() -> RegularChampionRotationModel {
    .init(
      observedAt: observedAt!,
      champions: regularChampions
    )
  }

  func toBeginnerRotation() -> BeginnerChampionRotationModel {
    .init(
      observedAt: observedAt!,
      maxLevel: beginnerMaxLevel,
      champions: beginnerChampions
    )
  }
}
