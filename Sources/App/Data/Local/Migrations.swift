import Fluent

extension Migrations {
  func addAppMigrations() {
    add(InitialSchema())
    add(AddPatchVersions())
    add(AddNotificationConfigs())
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
