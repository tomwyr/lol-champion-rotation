protocol GraphQLClient: Sendable {
  func execute<T>(
    endpoint: String,
    query: String,
    headers: [String: String],
    variables: [String: String],
    into type: T.Type,
  ) async throws -> T where T: Decodable & Sendable
}

struct NetworkGraphQLClient: GraphQLClient {
  let http: HttpClient

  func execute<T>(
    endpoint: String,
    query: String,
    headers: [String: String] = [:],
    variables: [String: String] = [:],
    into type: T.Type = T.self,
  ) async throws -> T where T: Decodable & Sendable {
    let defaultHeaders = [
      "Content-Type": "application/json",
      "Accept": "application/json",
    ]
    let finalHeaders = headers.merging(defaultHeaders) { _, second in second }

    var body: [String: Encodable] = [:]
    body["variables"] = variables
    body["query"] = query

    let response = try await http.post(
      to: endpoint,
      into: GraphQLResponse<T>.self,
      with: finalHeaders,
      sending: body,
    )

    if let errors = response.errors, !errors.isEmpty {
      throw errors.first!
    }
    guard let data = response.data else {
      throw GraphQLClientError.unexpectedResponseType(response)
    }
    return data
  }
}

enum GraphQLClientError<T>: Error where T: Decodable & Sendable {
  case unexpectedResponseType(GraphQLResponse<T>)
}

struct GraphQLRequest: Encodable {
  let query: String
  let variables: [String: String]
}

struct GraphQLResponse<T: Decodable & Sendable>: Decodable, Sendable {
  let data: T?
  let errors: [GraphQLError]?
}

struct GraphQLError: Decodable, Error {
  let message: String
}
