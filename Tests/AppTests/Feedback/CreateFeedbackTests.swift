import Testing

@testable import App

extension AppTests {
  @Suite(.serialized) struct CreateFeedbackTests {
    @Test func invalidAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(),
          body: ["title": "feedback", "description": "content"],
        ) { res async throws in
          #expect(res.status == .unauthorized)
        }
      }
    }

    @Test func validAuth() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["title": "feedback", "description": "content"],
        ) { res async throws in
          #expect(res.status == .noContent)
        }
      }
    }

    @Test func feedbackWithValidData() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["title": "feedback", "description": "content"],
        ) { res async throws in
          #expect(res.status == .noContent)
        }
      }
    }

    @Test func feedbackWithoutTitle() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["description": "content"],
        ) { res async throws in
          #expect(res.status == .noContent)
        }
      }
    }

    @Test func feedbackWithoutDescription() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["title": "feedback"],
        ) { res async throws in
          #expect(res.status == .badRequest)
        }
      }
    }

    @Test func feedbackWithEmptyTitle() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["title": "", "description": "content"],
        ) { res async throws in
          #expect(res.status == .badRequest)
          try expectBodyError(res.body, "Invalid input: Title must not be empty")
        }
      }
    }

    @Test func feedbackWithTooLongTitle() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        let maxLength = UserFeedback.titleMaxLength
        let title = String(repeating: "a", count: maxLength + 1)

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["title": title, "description": "content"],
        ) { res async throws in
          #expect(res.status == .badRequest)
          try expectBodyError(
            res.body,
            "Invalid input: Title must not exceed \(maxLength) characters",
          )
        }
      }
    }

    @Test func feedbackWithEmptyDescription() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["title": "feedback", "description": ""],
        ) { res async throws in
          #expect(res.status == .badRequest)
          try expectBodyError(res.body, "Invalid input: Description must not be empty")
        }
      }
    }

    @Test func feedbackWithTooLongDescription() async throws {
      try await withApp { app in
        _ = try await app.testConfigureWith()

        let maxLength = UserFeedback.descriptionMaxLength
        let description = String(repeating: "a", count: maxLength + 1)

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["title": "feedback", "description": description],
        ) { res async throws in
          #expect(res.status == .badRequest)
          try expectBodyError(
            res.body,
            "Invalid input: Description must not exceed \(maxLength) characters",
          )
        }
      }
    }

    @Test func linearIssueCreation() async throws {
      try await withApp { app in
        let issueData = CreateIssueData(issueCreate: CreateIssueResult(success: true))

        let mocks = try await app.testConfigureWith(
          linearAccessToken: "123",
          linearTeamId: "456",
          linearFeedbackStateId: "789",
          linearCreateIssueData: issueData,
        )

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["title": "feedback", "description": "content"],
        ) { res async throws in
          #expect(res.status == .noContent)
          #expect(mocks.graphQLClient.requestedQueries == [LinearClient.createIssueMutation])
          let expectedVariables = [
            "teamId": "456",
            "stateId": "789",
            "title": "feedback",
            "description": "content",
          ]
          #expect(mocks.graphQLClient.requestedVariables == [expectedVariables])
          let expectedHeaders = ["Authorization": "123"]
          #expect(mocks.graphQLClient.requestedHeaders == [expectedHeaders])
        }
      }
    }

    @Test func linearIssueCreationWithoutTitle() async throws {
      try await withApp { app in
        let issueData = CreateIssueData(issueCreate: CreateIssueResult(success: true))

        let mocks = try await app.testConfigureWith(
          linearAccessToken: "123",
          linearTeamId: "456",
          linearFeedbackStateId: "789",
          linearCreateIssueData: issueData,
        )

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["description": "content"],
        ) { res async throws in
          #expect(res.status == .noContent)
          #expect(mocks.graphQLClient.requestedQueries == [LinearClient.createIssueMutation])
          let expectedVariables = [
            "teamId": "456",
            "stateId": "789",
            "title": "Untitled",
            "description": "content",
          ]
          #expect(mocks.graphQLClient.requestedVariables == [expectedVariables])
        }
      }
    }

    @Test func linearIssueCreationWithBugType() async throws {
      try await withApp { app in
        let issueData = CreateIssueData(issueCreate: CreateIssueResult(success: true))

        let mocks = try await app.testConfigureWith(
          linearAccessToken: "123",
          linearTeamId: "456",
          linearFeedbackStateId: "789",
          linearCreateIssueData: issueData,
        )

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["title": "feedback", "description": "content", "type": "bug"],
        ) { res async throws in
          #expect(res.status == .noContent)
          #expect(mocks.graphQLClient.requestedQueries == [LinearClient.createIssueMutation])
          let expectedVariables = [
            "teamId": "456",
            "stateId": "789",
            "title": "[Bug] feedback",
            "description": "content",
          ]
          #expect(mocks.graphQLClient.requestedVariables == [expectedVariables])
        }
      }
    }

    @Test func linearIssueCreationWithFeatureType() async throws {
      try await withApp { app in
        let issueData = CreateIssueData(issueCreate: CreateIssueResult(success: true))

        let mocks = try await app.testConfigureWith(
          linearAccessToken: "123",
          linearTeamId: "456",
          linearFeedbackStateId: "789",
          linearCreateIssueData: issueData,
        )

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["title": "feedback", "description": "content", "type": "feature"],
        ) { res async throws in
          #expect(res.status == .noContent)
          #expect(mocks.graphQLClient.requestedQueries == [LinearClient.createIssueMutation])
          let expectedVariables = [
            "teamId": "456",
            "stateId": "789",
            "title": "[Feature] feedback",
            "description": "content",
          ]
          #expect(mocks.graphQLClient.requestedVariables == [expectedVariables])
        }
      }
    }

    @Test func linearIssueCreationWithUnknownType() async throws {
      try await withApp { app in
        let issueData = CreateIssueData(issueCreate: CreateIssueResult(success: true))

        let mocks = try await app.testConfigureWith(
          linearAccessToken: "123",
          linearTeamId: "456",
          linearFeedbackStateId: "789",
          linearCreateIssueData: issueData,
        )

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["title": "feedback", "description": "content", "type": "other"],
        ) { res async throws in
          #expect(res.status == .badRequest)
          #expect(mocks.graphQLClient.requestedVariables.isEmpty)

        }
      }
    }

    @Test func linearIssueCreationUnsuccessful() async throws {
      try await withApp { app in
        let issueData = CreateIssueData(issueCreate: CreateIssueResult(success: false))

        _ = try await app.testConfigureWith(
          linearAccessToken: "123",
          linearTeamId: "456",
          linearFeedbackStateId: "789",
          linearCreateIssueData: issueData,
        )

        try await app.test(
          .POST, "/feedbacks",
          headers: reqHeaders(accessToken: mobileToken),
          body: ["title": "feedback", "description": "content"],
        ) { res async throws in
          #expect(res.status == .internalServerError)
          try expectBodyError(res.body, "Failed to create feedback record")
        }
      }
    }
  }
}
