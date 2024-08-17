import XCTVapor

func XCTAssertBodyError(_ body: ByteBuffer, _ reason: String) {
  XCTAssertBody(body, ["error": true, "reason": reason])
}

func XCTAssertBody(
  _ body: ByteBuffer, _ test: [String: Any],
  file: StaticString = #filePath, line: UInt = #line
) {
  if let data = body.getData(at: body.readerIndex, length: body.readableBytes),
    let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
  {
    XCTAssertEqual(jsonObject as NSDictionary, test as NSDictionary)
  } else {
    XCTFail("Failed to decode JSON object from response body", file: file, line: line)
  }
}