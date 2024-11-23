struct VersionService {
  let riotApiClient: RiotApiClient
  let appDatabase: AppDatabase

  func latestVersion() async throws(PatchVersionError) -> String {
    guard let latestVersion = try await getLatestLocalVersion() else {
      throw .localVersionMissing
    }
    return latestVersion.value
  }

  func refreshVersion() async throws(PatchVersionError) {
    let riotVersion = try await getLatestRiotVersion()
    let localVersion = try await getLatestLocalVersion()
    if localVersion == nil || riotVersion > localVersion! {
      try await updateLatestLocalVersion(riotVersion)
    }
  }

  private func getLatestRiotVersion() async throws(PatchVersionError) -> SemanticVersion {
    let allVersions: [String]
    do {
      allVersions = try await riotApiClient.patchVersions()
    } catch {
      throw .dataUnavailable(cause: error)
    }

    guard let latestVersion = allVersions.compactMap(SemanticVersion.init(try:)).latest else {
      throw .noValidRiotVersion(allVersions: allVersions)
    }
    return latestVersion
  }

  private func getLatestLocalVersion() async throws(PatchVersionError) -> SemanticVersion? {
    do {
      let version = try await appDatabase.latestPatchVersion()?.value
      return if let version {
        try SemanticVersion(version)
      } else {
        nil
      }
    } catch {
      throw .dataUnavailable(cause: error)
    }
  }

  private func updateLatestLocalVersion(_ version: SemanticVersion) async throws(PatchVersionError)
  {
    let data = PatchVersionModel(value: version.value)
    do {
      try await appDatabase.savePatchVersion(data: data)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }
}

enum PatchVersionError: Error {
  case dataUnavailable(cause: Error)
  case localVersionMissing
  case noValidRiotVersion(allVersions: [String])
  case dataOperationFailed(cause: Error)
}
