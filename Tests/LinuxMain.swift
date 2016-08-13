#if os(Linux)

import XCTest
@testable import HTTPSerializerTests

XCTMain([
    testCase(HTTPSerializerTests.allTests)
])

#endif
