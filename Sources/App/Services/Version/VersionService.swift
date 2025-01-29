import Foundation

protocol VersionService {
  func latestVersion() async throws(PatchVersionError) -> String
  func findVersion(olderThan: Date) async throws(PatchVersionError) -> String
  func refreshVersion() async throws(PatchVersionError) -> RefreshVersionResult
}

struct DefaultVersionService<Version: RiotPatchVersion>: VersionService {
  let versionType: Version.Type
  let riotApiClient: RiotApiClient
  let appDatabase: AppDatabase

  func latestVersion() async throws(PatchVersionError) -> String {
    let data = try await getLocalVersion(using: appDatabase.latestPatchVersion)
    guard let version = data?.rawValue else {
      throw .latestVersionUnknown
    }
    return version
  }

  func findVersion(olderThan: Date) async throws(PatchVersionError) -> String {
    let data = try await getLocalVersion {
      try await appDatabase.patchVersion(olderThan: olderThan)
    }
    guard let version = data?.rawValue else {
      throw .latestVersionUnknown
    }
    return version
  }

  func refreshVersion() async throws(PatchVersionError) -> RefreshVersionResult {
    let localVersion = try await getLocalVersion(using: appDatabase.latestPatchVersion)
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

  private func getLocalVersion(using queryModel: () async throws -> PatchVersionModel?)
    async throws(PatchVersionError) -> Version?
  {
    let value: String?
    do {
      value = try await queryModel()?.value
    } catch {
      throw .dataUnavailable(cause: error)
    }

    guard let value else { return nil }

    guard let latestVersion = try? Version(rawValue: value) else {
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

  private func resolveVersion(_ localVersion: Version?, _ riotVersion: Version)
    -> ResolveVersionResult<Version>
  {
    guard let localVersion else {
      return (versionChanged: true, latestVersion: riotVersion)
    }
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
  case latestVersionUnknown
  case versionNotFound(olderThan: Date)
  case localVersionInvalid(value: String?)
  case noValidRiotVersion(allVersions: [String])
  case dataOperationFailed(cause: Error)
}
