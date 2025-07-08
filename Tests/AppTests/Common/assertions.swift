import Foundation
import NIO
import Testing

func expectBodyError(_ body: ByteBuffer, _ reason: String) throws {
  try expectBody(body, ["error": true, "reason": reason])
}

func expectBody(_ body: ByteBuffer, at path: String? = nil, _ expected: [String: Any?]) throws {
  let jsonObject = try #require(
    body.getData(at: body.readerIndex, length: body.readableBytes).flatMap { data in
      try? JSONSerialization.jsonObject(with: data) as? NSDictionary
    },
    "Failed to decode JSON object from response body",
  )

  let actual: NSDictionary
  if let path {
    let pathJsonObject = try #require(
      jsonObject[path] as? NSDictionary,
      "Expected an object in the response body at path \(path)",
    )
    actual = pathJsonObject
  } else {
    actual = jsonObject
  }

  #expect(expected as NSDictionary == actual)
}

func expectBody(_ body: ByteBuffer, at path: String? = nil, _ expected: NSArray) throws {
  let data = try #require(
    body.getData(at: body.readerIndex, length: body.readableBytes),
    "Failed to decode JSON data from response body",
  )

  let actual: NSArray
  if let path {
    let jsonObject = try #require(
      try? JSONSerialization.jsonObject(with: data) as? NSDictionary,
      "Failed to decode JSON object from response body",
    )

    let pathJsonList = try #require(
      jsonObject[path] as? NSArray,
      "Expected a list in the response body at path \(path)",
    )
    actual = pathJsonList
  } else {
    let jsonList = try #require(
      try? JSONSerialization.jsonObject(with: data) as? NSArray,
      "Failed to decode JSON list from response body",
    )
    actual = jsonList
  }

  #expect(expected == actual)
}
