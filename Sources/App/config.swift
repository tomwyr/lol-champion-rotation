import Vapor

struct AppConfig {
  var databaseUrl: String
  var appAllowedOrigins: [String]
  var appManagementKey: String
  var b2AppKeyId: String
  var b2AppKeySecret: String
  var riotApiKey: String
  var idHasherSecretKey: String
  var idHasherNonce: String

  static func fromEnvironment() -> AppConfig {
    AppConfig(
      databaseUrl: read("DATABASE_URL"),
      appAllowedOrigins: read("APP_ALLOWED_ORIGINS").split(separator: ","),
      appManagementKey: read("APP_MANAGEMENT_KEY"),
      b2AppKeyId: read("B2_APP_KEY_ID"),
      b2AppKeySecret: read("B2_APP_KEY_SECRET"),
      riotApiKey: read("RIOT_API_KEY"),
      idHasherSecretKey: read("ID_HASHER_SECRET_KEY"),
      idHasherNonce: read("ID_HASHER_NONCE")
    )
  }
}

private func read(_ key: String) -> String {
  guard let value = Environment.get(key) else {
    fatalError("Environment variable \(key) is not set!")
  }
  return value
}
