protocol VersionService {
  func latestVersion() async throws(PatchVersionError) -> String
  func refreshVersion() async throws(PatchVersionError) -> RefreshVersionResult
}

struct DefaultVersionService<Version: RiotPatchVersion>: VersionService {
  let versionType: Version.Type
  let riotApiClient: RiotApiClient
  let appDatabase: AppDatabase

  func latestVersion() async throws(PatchVersionError) -> String {
    try await getLatestLocalVersion().rawValue
  }

  func refreshVersion() async throws(PatchVersionError) -> RefreshVersionResult {
    let localVersion = try await getLatestLocalVersion()
    let riotVersion = try await getLatestRiotVersion()

    let (versionChanged, latestVersion) = resolveVersion(localVersion, riotVersion)
    if versionChanged {
      try await saveLatestLocalVersion(latestVersion)
    }

    return RefreshVersionResult(
      versionChanged: versionChanged,
      latestVersion: latestVersion.rawValue
    )
  }

  private func getLatestRiotVersion() async throws(PatchVersionError) -> Version {
    let allVersions: [String]
    do {
      allVersions = try await riotApiClient.patchVersions()
    } catch {
      throw .dataUnavailable(cause: error)
    }

    guard let latestVersion = Version.newestOf(versions: allVersions) else {
      throw .noValidRiotVersion(allVersions: allVersions)
    }
    return latestVersion
  }

  private func getLatestLocalVersion() async throws(PatchVersionError) -> Version {
    let value: String?
    do {
      value = try await appDatabase.latestPatchVersion()?.value
    } catch {
      throw .dataUnavailable(cause: error)
    }

    guard let value, let latestVersion = try? Version(rawValue: value) else {
      throw .localVersionInvalid(value: value)
    }
    return latestVersion
  }

  private func saveLatestLocalVersion(_ version: Version)
    async throws(PatchVersionError)
  {
    let data = PatchVersionModel(value: version.rawValue)
    do {
      try await appDatabase.savePatchVersion(data: data)
    } catch {
      throw .dataOperationFailed(cause: error)
    }
  }

  private func resolveVersion(_ localVersion: Version, _ riotVersion: Version)
    -> ResolveVersionResult<Version>
  {
    return if Version.increased(from: localVersion, to: riotVersion) {
      (versionChanged: true, latestVersion: riotVersion)
    } else {
      (versionChanged: false, latestVersion: localVersion)
    }
  }
}

private typealias ResolveVersionResult<Version: RiotPatchVersion> = (
  versionChanged: Bool, latestVersion: Version
)

enum PatchVersionError: Error {
  case dataUnavailable(cause: Error)
  case localVersionInvalid(value: String?)
  case noValidRiotVersion(allVersions: [String])
  case dataOperationFailed(cause: Error)
}
