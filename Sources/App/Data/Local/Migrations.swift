import Fluent
import FluentSQL
import Foundation

extension Migrations {
  func addAppMigrations() {
    add(InitialSchema())
    add(AddPatchVersions())
    add(AddNotificationConfigs())
    add(SplitChampionRotations())
    add(AddChampionTitle())
    add(AddChampionReleaseDate())
    add(ChangeDeviceIdToUserId())
    add(AddUserWatchlists())
    add(AddChampionsToUserWatchlists())
    add(AddChampionsAvailableNotification())
    add(AddChampionRotationSlugs())
    add(AddChampionRotationPredictions())
  }
}

struct InitialSchema: AsyncMigration {
  func prepare(on db: any Database) async throws {
    try await db.schema("champion-rotations")
      .id()
      .field("observed_at", .datetime)
      .field("beginner_max_level", .int)
      .field("beginner_champions", .array(of: .string))
      .field("regular_champions", .array(of: .string))
      .create()

    try await db.schema("champions")
      .id()
      .field("riot_id", .string)
      .field("name", .string)
      .create()
  }

  func revert(on db: any Database) async throws {
    try await db.schema("champion-rotations").delete()
    try await db.schema("champions").delete()
  }
}

struct AddPatchVersions: AsyncMigration {
  func prepare(on db: any Database) async throws {
    try await db.schema("patch-versions")
      .id()
      .field("observed_at", .datetime)
      .field("value", .string)
      .create()
  }

  func revert(on db: any Database) async throws {
    try await db.schema("patch-versions").delete()
  }
}

struct AddNotificationConfigs: AsyncMigration {
  func prepare(on db: any Database) async throws {
    try await db.schema("notifications-configs")
      .id()
      .field("device_id", .string)
      .field("token", .string)
      .field("enabled", .bool)
      .create()
  }

  func revert(on db: any Database) async throws {
    try await db.schema("notifications-configs").delete()
  }
}

struct SplitChampionRotations: AsyncMigration {
  func prepare(on db: any Database) async throws {
    try await createRegularRotationsTable(db)
    try await createBeginnerRotationsTable(db)
    try await populateRegularRotations(db)
    try await populateBeginnerRotations(db)
    try await deleteCombinedRotationsTable(db)
  }

  func revert(on db: any Database) async throws {
    try await createCombinedRotationsTable(db)
    try await deleteSplitRotationsTables(db)
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

    var regularRotations = [OldRegularChampionRotationModel]()
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

struct AddChampionTitle: AsyncMigration {
  func prepare(on db: any Database) async throws {
    try await db.schema("champions")
      .field("title", .string)
      .update()
  }

  func revert(on db: any Database) async throws {
    try await db.schema("champions")
      .deleteField("title")
      .update()
  }
}

struct AddChampionReleaseDate: AsyncMigration {
  func prepare(on db: any Database) async throws {
    try await db.schema("champions")
      .field("released_at", .datetime)
      .update()
  }

  func revert(on db: any Database) async throws {
    try await db.schema("champions")
      .deleteField("released_at")
      .update()
  }
}

struct ChangeDeviceIdToUserId: AsyncMigration {
  func prepare(on db: any Database) async throws {
    try await db.query(NotificationsConfigModel.self).delete()
    try await db.schema("notifications-configs")
      .deleteField("device_id")
      .field("user_id", .string)
      .update()
  }

  func revert(on db: any Database) async throws {
    try await db.query(NotificationsConfigModel.self).delete()
    try await db.schema("notifications-configs")
      .deleteField("user_id")
      .field("device_id", .string)
      .update()
  }
}

struct AddUserWatchlists: AsyncMigration {
  func prepare(on db: any Database) async throws {
    try await db.schema("user-watchlists")
      .id()
      .field("user_id", .string)
      .field("rotations", .array(of: .string))
      .create()
  }

  func revert(on db: any Database) async throws {
    try await db.schema("user-watchlists").delete()
  }
}

struct AddChampionsToUserWatchlists: AsyncMigration {
  func prepare(on db: any Database) async throws {
    try await db.schema("user-watchlists")
      .field("champions", .array(of: .string))
      .update()

    try await UserWatchlistsModel.query(on: db)
      .set(\.$champions, to: [])
      .update()
  }

  func revert(on db: any Database) async throws {
    try await db.schema("user-watchlists")
      .deleteField("champions")
      .update()
  }
}

struct AddChampionsAvailableNotification: AsyncMigration {
  func prepare(on db: any Database) async throws {
    try await db.schema("notifications-configs")
      .field("rotation_changed", .bool)
      .field("champions_available", .bool)
      .update()

    try await (db as! SQLDatabase).raw(
      """
      UPDATE "notifications-configs"
      SET rotation_changed = enabled, champions_available = false
      """
    ).run()

    try await db.schema("notifications-configs")
      .deleteField("enabled")
      .update()
  }

  func revert(on db: any Database) async throws {
    try await db.schema("notifications-configs")
      .field("enabled", .bool)
      .update()

    try await (db as! SQLDatabase).raw(
      """
      UPDATE "notifications-configs"
      SET enabled = rotation_changed
      """
    ).run()

    try await db.schema("notifications-configs")
      .deleteField("rotation_changed")
      .deleteField("champions_available")
      .update()
  }
}

struct AddChampionRotationSlugs: AsyncMigration {
  func prepare(on db: any Database) async throws {
    try await createSlugField(db)
    try await populateSlugs(db)
  }

  func revert(on db: any Database) async throws {
    try await deleteSlugField(db)
  }

  private func createSlugField(_ db: any Database) async throws {
    try await db.schema("regular-champion-rotations")
      .field("slug", .string)
      .update()

    try await RegularChampionRotationModel.query(on: db)
      .set(\.$slug, to: "")
      .update()
  }

  private func deleteSlugField(_ db: any Database) async throws {
    try await db.schema("regular-champion-rotations")
      .deleteField("slug")
      .update()
  }

  private func populateSlugs(_ db: any Database) async throws {
    let rotations = try await RegularChampionRotationModel.query(on: db).all()
    let versions = try await PatchVersionModel.query(on: db).all()

    let slugs = try SlugGenerator().resolveAllUnique(
      rotationStarts: rotations.map(\.observedAt),
      versions: versions,
      existingSlugs: rotations.map(\.slug),
    )
    for (rotation, slug) in zip(rotations, slugs) {
      rotation.slug = slug
      try await rotation.save(on: db)
    }
  }
}

struct AddChampionRotationPredictions: AsyncMigration {
  func prepare(on db: Database) async throws {
    try await db.schema("champion-rotation-predictions")
      .id()
      .field("previous_rotation_id", .uuid)
      .field("champions", .array(of: .string))
      .create()
  }

  func revert(on db: Database) async throws {
    try await db.schema("champion-rotation-predictions").delete()
  }
}

extension ChampionRotationModel {
  func toRegularRotation() -> OldRegularChampionRotationModel {
    .init(
      observedAt: observedAt!,
      champions: regularChampions,
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
