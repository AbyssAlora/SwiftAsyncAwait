import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(SwiftAsyncAwaitTests.allTests),
        testCase(SwiftAsyncAwaitPerformanceTests.allTests)
    ]
}
#endif
