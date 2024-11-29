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

  guard let data = body.getData(at: body.readerIndex, length: body.readableBytes),
    let jsonObject = try? JSONSerialization.jsonObject(with: data) as? NSDictionary
  else {
    fail("Failed to decode JSON object from response body")
    return
  }

  let actual: NSDictionary
  if let path {
    guard let pathJsonObject = jsonObject[path] as? NSDictionary else {
      fail("Expected an object in the response body at path \(path)")
      return
    }
    actual = pathJsonObject
  } else {
    actual = jsonObject
  }

  XCTAssertEqual(expected, actual)
}

func XCTAssertBody(
  _ body: ByteBuffer,
  at path: String? = nil,
  _ expected: NSArray,
  file: StaticString = #filePath, line: UInt = #line
) {
  let fail = { (message: String) in XCTFail(message, file: file, line: line) }

  guard let data = body.getData(at: body.readerIndex, length: body.readableBytes) else {
    fail("Failed to decode JSON data from response body")
    return
  }

  let actual: NSArray
  if let path {
    guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? NSDictionary else {
      fail("Failed to decode JSON object from response body")
      return
    }
    guard let pathJsonList = jsonObject[path] as? NSArray else {
      NSLog(String(describing: jsonObject[path]))
      fail("Expected a list in the response body at path \(path)")
      return
    }
    actual = pathJsonList
  } else {
    guard let jsonList = try? JSONSerialization.jsonObject(with: data) as? NSArray else {
      fail("Failed to decode JSON list from response body")
      return
    }
    actual = jsonList
  }

  XCTAssertEqual(expected, actual)
}
