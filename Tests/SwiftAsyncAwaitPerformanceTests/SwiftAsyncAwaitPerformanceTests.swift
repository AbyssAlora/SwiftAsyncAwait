import XCTest
@testable import SwiftAsyncAwait

struct Constants {
    static let tests = 100_000
}

final class SwiftAsyncAwaitPerformanceTests: XCTestCase {

    @discardableResult public func measure(label: String? = nil, tests: Int = Constants.tests, printResults output: Bool = true, setup: @escaping () -> Void = { return }, _ block: @escaping () -> Void) -> Double {

        guard tests > 0 else { fatalError("Number of tests must be greater than 0") }

        var avgExecutionTime : CFAbsoluteTime = 0
        for _ in 1...tests {
            setup()
            let start = CFAbsoluteTimeGetCurrent()
            block()
            let end = CFAbsoluteTimeGetCurrent()
            avgExecutionTime += end - start
        }

        avgExecutionTime /= CFAbsoluteTime(tests)

        if output {
            let avgTimeStr = String(format: "%.013f", avgExecutionTime) // Kill da all mdfks with format of 13 decimals

            if let label = label {
                let outputString = String(
                        format: "Execution time: %@ \t -> \t %@",
                        avgTimeStr, label
                )
                print("NT:", String(format: "%07d", tests),"\t", outputString)
            }
        }

        return avgExecutionTime
    }

    // MARK: GCD
    func testDispatchAsyncOnSerialQueue() {
        // Arrange.
        let expectation = self.expectation(description: "")
        expectation.expectedFulfillmentCount = Constants.tests
        let queue = DispatchQueue(label: #function, qos: .userInitiated)
        let semaphore = DispatchSemaphore(value: 0)

        // Act.
        DispatchQueue.main.async {
            self.measure(label: "\(#function)") {
                queue.async {
                    semaphore.signal()
                    expectation.fulfill()
                }
                semaphore.wait()
            }
        }

        // Assert.
        waitForExpectations(timeout: 20)
    }

    /// Measures the average time needed to get into a doubly nested dispatch_async block.
    func testDoubleDispatchAsyncOnSerialQueue() {
        // Arrange.
        let expectation = self.expectation(description: "")
        expectation.expectedFulfillmentCount = Constants.tests
        let queue = DispatchQueue(label: #function, qos: .userInitiated)
        let semaphore = DispatchSemaphore(value: 0)

        // Act.
        DispatchQueue.main.async {
            self.measure(label: "\(#function)") {
                queue.async {
                    queue.async {
                        semaphore.signal()
                        expectation.fulfill()
                    }
                }
                semaphore.wait()
            }
        }

        // Assert.
        waitForExpectations(timeout: 10)
    }

    func testTripleDispatchAsyncOnSerialQueue() {
        // Arrange.
        let expectation = self.expectation(description: "")
        expectation.expectedFulfillmentCount = Constants.tests
        let queue = DispatchQueue(label: #function, qos: .userInitiated)
        let semaphore = DispatchSemaphore(value: 0)

        // Act.
        DispatchQueue.main.async {
            self.measure(label: "\(#function)") {
                queue.async {
                    queue.async {
                        queue.async {
                            semaphore.signal()
                            expectation.fulfill()
                        }
                    }
                }
                semaphore.wait()
            }
        }

        // Assert.
        waitForExpectations(timeout: 10)
    }

    /// Measures the total time needed to perform a lot of `DispatchQueue.Async` blocks on
    /// a concurrent queue.
    func testDispatchAsyncOnConcurrentQueue() {
        // Arrange.
        let queue = DispatchQueue(label: #function, qos: .userInitiated, attributes: .concurrent)
        let group = DispatchGroup()
        var blocks = [() -> Void]()
        for _ in 0..<Constants.tests {
            group.enter()
            blocks.append({
                group.leave()
            })
        }

        self.measure(label: "\(#function)", tests: 1) {
            for block in blocks {
                queue.async {
                    block()
                }
            }

            // Assert.
            XCTAssert(group.wait(timeout: .now() + 1) == .success)
        }
    }



    // MARK: AsyncAwait

    func testAsyncAwaitOnSerialQueue() {
        // Arrange.
        let expectation = self.expectation(description: "")
        expectation.expectedFulfillmentCount = Constants.tests
        let queue = DispatchQueue(label: #function, qos: .userInitiated)
        let semaphore = DispatchSemaphore(value: 0)

        // Act.
        DispatchQueue.main.async {
            self.measure(label: "\(#function)") {
                Async<Bool>(on: queue) {
                    semaphore.signal()
                    expectation.fulfill()
                    return true
                }
                semaphore.wait()
            }
        }

        // Assert.
        waitForExpectations(timeout: 20)
    }

    func testDoubleAsyncAwaitOnSerialQueue() {
        // Arrange.
        let expectation = self.expectation(description: "")
        expectation.expectedFulfillmentCount = Constants.tests
        let queue = DispatchQueue(label: #function, qos: .userInitiated)
        let semaphore = DispatchSemaphore(value: 0)

        // Act.
        DispatchQueue.main.async {
            self.measure(label: "\(#function)") {
                Async(on: queue) {
                    Async(on: queue) {
                        semaphore.signal()
                        expectation.fulfill()
                    }
                }
                semaphore.wait()
            }
        }

        // Assert.
        waitForExpectations(timeout: 20)
    }

    func testTripleAsyncAwaitOnSerialQueue() {
        // Arrange.
        let expectation = self.expectation(description: "")
        expectation.expectedFulfillmentCount = Constants.tests
        let queue = DispatchQueue(label: #function, qos: .userInitiated)
        let semaphore = DispatchSemaphore(value: 0)

        // Act.
        DispatchQueue.main.async {
            self.measure(label: "\(#function)") {
                Async(on: queue) {
                    Async(on: queue) {
                        Async(on: queue) {
                            semaphore.signal()
                            expectation.fulfill()
                        }
                    }
                }
                semaphore.wait()
            }
        }

        // Assert.
        waitForExpectations(timeout: 20)
    }

    func testTripleAwaitAsyncAwaitOnSerialQueue() {
        // Arrange.
        let expectation = self.expectation(description: "")
        expectation.expectedFulfillmentCount = Constants.tests
        let queue = DispatchQueue(label: #function, qos: .userInitiated)
        let semaphore = DispatchSemaphore(value: 0)

        // Act.
        DispatchQueue.main.async {
            self.measure(label: "\(#function)") {
                try! await { Async(on: queue) { } }
                try! await { Async(on: queue) { } }
                Async(on: queue) {
                    semaphore.signal()
                    expectation.fulfill()
                }
                semaphore.wait()
            }
        }

        // Assert.
        waitForExpectations(timeout: 20)
    }

    /// a concurrent queue.
    func testAsyncAwaitOnConcurrentQueue() {
        // Arrange.
        let queue = DispatchQueue(label: #function, qos: .userInitiated, attributes: .concurrent)
        let group = DispatchGroup()
        var blocks = [Task]()
        for _ in 0..<Constants.tests {
            group.enter()
            blocks.append(
                    Async(on: queue, state: .pending) {
                        group.leave()
                    }
            )
        }

        self.measure(label: "\(#function)", tests: 1) {
            for block in blocks {
                block.start()
            }

            // Assert.
            XCTAssert(group.wait(timeout: .now() + 1) == .success)
        }
    }

    // MARK: AsyncAwait

    func testPromiseOnSerialQueue() {
        // Arrange.
        let expectation = self.expectation(description: "")
        expectation.expectedFulfillmentCount = Constants.tests
        let queue = DispatchQueue(label: #function, qos: .userInitiated)
        let semaphore = DispatchSemaphore(value: 0)

        // Act.
        DispatchQueue.main.async {
            self.measure(label: "\(#function)") {
                Promise<Bool>(on: queue) {
                    semaphore.signal()
                    expectation.fulfill()
                    return true
                }.start()
                semaphore.wait()
            }
        }

        // Assert.
        waitForExpectations(timeout: 20)
    }

    func testDoubleThenOnSerialQueue() {
        // Arrange.
        let expectation = self.expectation(description: "")
        expectation.expectedFulfillmentCount = Constants.tests
        let queue = DispatchQueue(label: #function, qos: .userInitiated)
        let semaphore = DispatchSemaphore(value: 0)

        // Act.
        DispatchQueue.main.async {
            self.measure(label: "\(#function)") {
                Promise(on: queue) {

                }.then(on: queue) {
                    semaphore.signal()
                    expectation.fulfill()
                }
                semaphore.wait()
            }
        }

        // Assert.
        waitForExpectations(timeout: 20)
    }

    func testTripleThenOnSerialQueue() {
        // Arrange.
        let expectation = self.expectation(description: "")
        expectation.expectedFulfillmentCount = Constants.tests
        let queue = DispatchQueue(label: #function, qos: .userInitiated)
        let semaphore = DispatchSemaphore(value: 0)

        // Act.
        DispatchQueue.main.async {
            self.measure(label: "\(#function)") {
                Promise(on: queue) {

                }.then(on: queue) {

                }.then(on: queue) {
                    semaphore.signal()
                    expectation.fulfill()
                }
                semaphore.wait()
            }
        }

        // Assert.
        waitForExpectations(timeout: 20)
    }

    /// a concurrent queue.
    func testPromisesOnConcurrentQueue() {
        // Arrange.
        let queue = DispatchQueue(label: #function, qos: .userInitiated, attributes: .concurrent)
        let group = DispatchGroup()
        var blocks = [Task]()
        for _ in 0..<Constants.tests {
            group.enter()
            blocks.append(
                    Promise(on: queue) {
                        group.leave()
                    }
            )
        }

        self.measure(label: "\(#function)", tests: 1) {
            for block in blocks {
                block.start()
            }

            // Assert.
            XCTAssert(group.wait(timeout: .now() + 1) == .success)
        }
    }

    static var allTests = [
        ("testDispatchAsyncOnSerialQueue", testDispatchAsyncOnSerialQueue),
        ("testDoubleDispatchAsyncOnSerialQueue", testDoubleDispatchAsyncOnSerialQueue),
        ("testTripleDispatchAsyncOnSerialQueue", testTripleDispatchAsyncOnSerialQueue),
        ("testDispatchAsyncOnConcurrentQueue", testDispatchAsyncOnConcurrentQueue),
        ("testAsyncAwaitOnSerialQueue", testAsyncAwaitOnSerialQueue),
        ("testDoubleAsyncAwaitOnSerialQueue", testDoubleAsyncAwaitOnSerialQueue),
        ("testTripleAsyncAwaitOnSerialQueue", testTripleAsyncAwaitOnSerialQueue),
        ("testAsyncAwaitOnConcurrentQueue", testAsyncAwaitOnConcurrentQueue),
        ("testTripleAwaitAsyncAwaitOnSerialQueue", testTripleAwaitAsyncAwaitOnSerialQueue)
    ]
}