struct ImageProvider {
  let baseUrl: String

  func champion(with championId: String) -> String {
    "\(baseUrl)/assets/champions/\(championId).jpg"
  }
}
