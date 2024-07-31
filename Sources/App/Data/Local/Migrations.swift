import Fluent

extension Migrations {
  func addAppMigrations() {
    add(CreateChampionRotation())
  }
}

struct CreateChampionRotation: AsyncMigration {
  func prepare(on database: any Database) async throws {
    try await database.schema("champion-rotations")
      .id().field("observed_at", .datetime).field("champion_ids", .string)
      .create()
  }

  func revert(on database: any Database) async throws {
    try await database.schema("champion-rotations").delete()
  }
}
