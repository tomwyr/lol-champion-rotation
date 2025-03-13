import Vapor

extension ByteBuffer: @retroactive ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral value: (String, Any)...) {
    let dictionary = Dictionary(uniqueKeysWithValues: value)
    let data = try! JSONSerialization.data(withJSONObject: dictionary)
    self.init(data: data)
  }
}

func reqHeaders(accessToken: String? = nil) -> HTTPHeaders {
  var headers = [
    "Content-Type": "application/json"
  ]
  if let accessToken {
    headers["Authorization"] = "Bearer \(accessToken)"
  }
  return HTTPHeaders(headers.map { ($0, $1) })
}
