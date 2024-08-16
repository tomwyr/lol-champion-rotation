import Vapor

struct AppConfig {
  var databaseUrl: String
  var appManagementKey: String
  var b2AppKeyId: String
  var b2AppKeySecret: String
  var riotApiKey: String

  static func fromEnvironment() -> AppConfig {
    AppConfig(
      databaseUrl: Environment.get("DATABASE_URL")!,
      appManagementKey: Environment.get("APP_MANAGEMENT_KEY")!,
      b2AppKeyId: Environment.get("B2_APP_KEY_ID")!,
      b2AppKeySecret: Environment.get("B2_APP_KEY_SECRET")!,
      riotApiKey: Environment.get("RIOT_API_KEY")!
    )
  }
}
