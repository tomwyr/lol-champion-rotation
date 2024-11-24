import Fluent

struct AppDatabase {
  let database: Database
}

extension AppDatabase {
  func addChampionRotation(data: ChampionRotationModel) async throws {
    try await data.create(on: database)
  }

  func mostRecentChampionRotation() async throws -> ChampionRotationModel? {
    try await ChampionRotationModel.query(on: database).sort(\.$observedAt, .descending).first()
  }

  func champions() async throws -> [ChampionModel] {
    try await ChampionModel.query(on: database).all()
  }

  func saveChampionsFillingIds(data: [ChampionModel]) async throws {
    let championsByRiotId = try await champions().associateBy(\.riotId)

    try await database.transaction { database in
      for model in data {
        if let existingId = championsByRiotId[model.riotId]?.id {
          model.id = existingId
          model.$id.exists = true
          try await model.update(on: database)
        } else {
          try await model.create(on: database)
        }
      }
    }
  }
}

extension AppDatabase {
  func latestPatchVersion() async throws -> PatchVersionModel? {
    try await PatchVersionModel.query(on: database).sort(\.$observedAt, .descending).first()
  }

  func savePatchVersion(data: PatchVersionModel) async throws {
    try await data.create(on: database)
  }
}
