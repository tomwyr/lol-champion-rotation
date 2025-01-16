import Vapor

extension ByteBuffer: @retroactive ExpressibleByDictionaryLiteral {
  public init(dictionaryLiteral value: (String, Any)...) {
    let dictionary = Dictionary(uniqueKeysWithValues: value)
    let data = try! JSONSerialization.data(withJSONObject: dictionary)
    self.init(data: data)
  }
}

func reqHeaders(deviceId: String? = nil) -> HTTPHeaders {
  var headers = [
    "Content-Type": "application/json"
  ]
  if let deviceId {
    headers["X-Device-Id"] = deviceId
  }
  return HTTPHeaders(headers.map { ($0, $1) })
}
