import Fluent

struct AppDatabase {
  let database: Database

  func championRotations() async throws -> [ChampionRotationModel] {
    try await ChampionRotationModel.query(on: database).all()
  }

  func addChampionRotation(data: ChampionRotationModel) async throws {
    try await ChampionRotationModel.create(data)(on: database)
  }

  func mostRecentChampionRotation() async throws -> ChampionRotationModel? {
    try await ChampionRotationModel.query(on: database).sort(\.$observedAt, .descending).first()
  }
}
