import XCTest

import SwiftAsyncAwaitTests
import SwiftAsyncAwaitPerformanceTests

var tests = [XCTestCaseEntry]()
tests += SwiftAsyncAwaitTests.allTests()
tests += SwiftAsyncAwaitPerformanceTests.allTests()
XCTMain(tests)
