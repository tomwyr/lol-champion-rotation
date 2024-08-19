import Fluent

extension Migrations {
  func addAppMigrations() {
    add(CreateChampionRotation())
  }
}

struct CreateChampionRotation: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("champion-rotations")
      .id()
      .field("observed_at", .datetime)
      .field("beginner_max_level", .int)
      .field("beginner_champion_ids", .array(of: .string))
      .field("regular_champion_ids", .array(of: .string))
      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("champion-rotations").delete()
  }
}
