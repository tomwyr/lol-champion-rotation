struct LinearClient {
  let gql: GraphQLClient
  let accessToken: String

  func createIssue(
    teamId: String,
    stateId: String,
    title: String,
    description: String,
  ) async throws -> CreateIssueResult {
    try await gql.execute(
      endpoint: Self.endpoint,
      query: Self.createIssueMutation,
      headers: [
        "Authorization": accessToken
      ],
      variables: [
        "teamId": teamId,
        "stateId": stateId,
        "title": title,
        "description": description,
      ].compacted(),
      into: CreateIssueData.self,
    ).issueCreate
  }
}

struct CreateIssueResult: Codable {
  let success: Bool
}

struct CreateIssueData: Codable {
  let issueCreate: CreateIssueResult
}

extension LinearClient {
  static let endpoint = "https://api.linear.app/graphql"

  static let createIssueMutation = """
    mutation IssueCreate($teamId: String!, $stateId: String!, $title: String!, $description: String!) {
      issueCreate(
        input: {
          teamId: $teamId
          stateId: $stateId
          title: $title
          description: $description
        }
      ) {
        success
      }
    }
    """
}
