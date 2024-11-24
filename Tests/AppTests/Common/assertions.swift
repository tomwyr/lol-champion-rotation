import XCTVapor

func XCTAssertBodyError(_ body: ByteBuffer, _ reason: String) {
  XCTAssertBody(body, ["error": true, "reason": reason])
}

func XCTAssertBody(
  _ body: ByteBuffer,
  at path: String? = nil,
  _ expected: NSDictionary,
  file: StaticString = #filePath, line: UInt = #line
) {
  let fail = { (message: String) in XCTFail(message, file: file, line: line) }

  if let data = body.getData(at: body.readerIndex, length: body.readableBytes),
    let jsonObject = try? JSONSerialization.jsonObject(with: data) as? NSDictionary
  {
    if let path {
      guard let pathJsonObject = jsonObject[path] as? NSDictionary else {
        fail("Expected an object in the response body at path \(path)")
        return
      }
      XCTAssertEqual(expected, pathJsonObject)
    } else {
      XCTAssertEqual(expected, jsonObject)
    }
  } else {
    fail("Failed to decode JSON object from response body")
  }
}
