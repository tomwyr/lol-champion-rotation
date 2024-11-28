struct AppDatabase {
  let runner: DatabaseRunner
}

extension AppDatabase {
  func addChampionRotation(data: ChampionRotationModel) async throws {
    try await runner.run { db in
      try await data.create(on: db)
    }
  }

  func mostRecentChampionRotation() async throws -> ChampionRotationModel? {
    try await runner.run { db in
      try await ChampionRotationModel.query(on: db).sort(\.$observedAt, .descending).first()
    }
  }

  func champions() async throws -> [ChampionModel] {
    try await runner.run { db in

      try await ChampionModel.query(on: db).all()
    }
  }

  func saveChampionsFillingIds(data: [ChampionModel]) async throws {
    let championsByRiotId = try await champions().associateBy(\.riotId)

    try await runner.run { db in
      try await db.transaction { database in
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
}

extension AppDatabase {
  func latestPatchVersion() async throws -> PatchVersionModel? {
    try await runner.run { db in
      try await PatchVersionModel.query(on: db).sort(\.$observedAt, .descending).first()
    }
  }

  func savePatchVersion(data: PatchVersionModel) async throws {
    try await runner.run { db in
      try await data.create(on: db)
    }
  }
}
