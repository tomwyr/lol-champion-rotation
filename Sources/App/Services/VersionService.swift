struct VersionService {
  let riotApiClient: RiotApiClient
  let appDatabase: AppDatabase

  func latestVersion() async throws(PatchVersionError) -> String {
    guard let latestVersion = try await getLatestLocalVersion() else {
      throw .localVersionMissing
    }
    return latestVersion.value
  }

  func refreshVersion() async throws(PatchVersionError) -> RefreshVersionResult {
    let localVersion = try await getLatestLocalVersion()
    let riotVersion = try await getLatestRiotVersion()

    let (versionChanged, latestVersion) = resolveLatestVersion(localVersion, riotVersion)
    if versionChanged {
      try await saveLatestLocalVersion(latestVersion)
    }

    return RefreshVersionResult(
      versionChanged: versionChanged,
      latestVersion: latestVersion.value
    )
  }

  private func resolveLatestVersion(
    _ localVersion: SemanticVersion?, _ riotVersion: SemanticVersion
  ) -> ResolveVersionResult {
    guard let localVersion = localVersion else {
      return (true, riotVersion)
    }
    return if riotVersion > localVersion {
      (true, riotVersion)
    } else {
      (false, localVersion)
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

  private func saveLatestLocalVersion(_ version: SemanticVersion) async throws(PatchVersionError) {
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

private typealias ResolveVersionResult = (versionChanged: Bool, latestVersion: SemanticVersion)
