import Foundation
import NIO

struct B2ApiClient {
  let http: HttpClient
  let appKeyId: String
  let appKeySecret: String

  func authorizeAccount() async throws -> AuthorizationData {
    let token = "\(appKeyId):\(appKeySecret)".data(using: .utf8)!.base64EncodedString()

    return try await http.get(
      from: authorizeAccountUrl,
      into: AuthorizationData.self,
      with: ["Authorization": "Basic \(token)"]
    )
  }

  func getDownloadAuthorization(
    authorizationToken: String,
    fileNamePrefix: String? = nil,
    validDuration: TimeAmount? = nil
  ) async throws -> AuthorizationData {
    var body = [String: Encodable]()
    body["bucketId"] = bucketId
    if let fileNamePrefix {
      body["fileNamePrefix"] = fileNamePrefix
    }
    if let validDuration {
      body["validDurationInSeconds"] = Duration(validDuration).components.seconds
    }

    return try await http.post(
      to: getDownloadAuthorizationUrl,
      into: AuthorizationData.self,
      with: ["Authorization": authorizationToken],
      sending: body
    )
  }

  func fileUrl(for fileName: String, authorizeWith token: String? = nil) -> String {
    var url = "\(filesUrl)/\(fileName)"
    if let token = token {
      url += "?Authorization=\(token)"
    }
    return url
  }
}

private let bucketName = "lol-champion-rotation"
private let bucketId = "d5cd882b983206a895110416"

private let baseUrl = "https://api003.backblazeb2.com"
private let filesUrl = "\(baseUrl)/file/\(bucketName)"
private let apiUrl = "\(baseUrl)/b2api/v3"
private let authorizeAccountUrl = "\(apiUrl)/b2_authorize_account"
private let getDownloadAuthorizationUrl = "\(apiUrl)/b2_get_download_authorization"

struct AuthorizationData: Decodable {
  let authorizationToken: String
}
