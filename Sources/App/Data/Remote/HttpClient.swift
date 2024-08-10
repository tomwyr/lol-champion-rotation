import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

struct HttpClient {
  func get<T>(
    from url: String,
    into type: T.Type,
    with headers: [String: String] = [:]
  ) async throws -> T where T: Decodable {
    try await request(method: .get, from: url, into: type, with: headers)
  }

  func post<T>(
    from url: String,
    into type: T.Type,
    with headers: [String: String] = [:],
    sending body: [String: Encodable]
  ) async throws -> T where T: Decodable {
    try await request(method: .post, from: url, into: type, with: headers, sending: body)
  }

  private func request<T>(
    method: UrlRequestMethod,
    from url: String,
    into type: T.Type,
    with headers: [String: String],
    sending body: [String: Encodable]? = nil
  ) async throws -> T where T: Decodable {
    let bodyData = try body.map { try JSONSerialization.data(withJSONObject: $0) }
    let request = URLRequest(method: method, url: url, headers: headers, body: bodyData)
    let (data, response) = try await URLSession.shared.data(for: request)
    try validateResponse(response)
    return try JSONDecoder().decode(type.self, from: data)
  }

  private func validateResponse(_ response: URLResponse) throws {
    guard let response = response as? HTTPURLResponse else {
      throw HttpClientError.unexpectedResponseType(response)
    }
    guard 200..<300 ~= response.statusCode else {
      throw HttpClientError.requestUnsuccessful(response)
    }
  }
}

enum HttpClientError: Error {
  case unexpectedResponseType(URLResponse)
  case requestUnsuccessful(URLResponse)
}

enum UrlRequestMethod: String {
  case get = "GET"
  case post = "POST"
}

extension URLRequest {
  init(method: UrlRequestMethod, url: String, headers: [String: String], body: Data?) {
    self.init(url: URL(string: url)!)
    self.httpMethod = method.rawValue
    self.httpBody = body
    for (key, value) in headers {
      self.addValue(value, forHTTPHeaderField: key)
    }
  }
}
