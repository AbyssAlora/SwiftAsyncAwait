import XCTest
@testable import SwiftAsyncAwait

import Foundation

enum AsyncAwaitTestError: Error {
    case someError(String)
}

final class SwiftAsyncAwaitTests: XCTestCase {

    func syncFn(val: Int) -> Int {
        val
    }

    func asyncFn(val: Int) -> Async<Int> {
        Async {
            val
        }
    }

    func syncFnThrows(val: Int) throws -> Int {
        if val < 0 {
            throw AsyncAwaitTestError.someError("val {\(val)} is less then zero")
        }
        return val
    }

    func asyncFnThrows(val: Int) -> Async<Int> {
        Async {
            if val < 0 {
                throw AsyncAwaitTestError.someError("val {\(val)} is less then zero")
            }
            return val
        }
    }

    func soLongFn(val: Int) -> (Int, Int) {
        for _ in 1...val { }
        return (val, val * 2)
    }

    func testAsyncAwait() {
        let result = try! await { self.asyncFn(val: 100) }
        XCTAssertEqual(result, 100)
    }

    func testSyncAwait() {
        let task = Async { self.syncFn(val: 99) }
        let result = try! await { task }
        XCTAssertEqual(result, 99)
    }

    func testAsyncAwaitThrow() {
        do {
            try await { self.asyncFnThrows(val: -1) }
        } catch AsyncAwaitTestError.someError(let msg) {
            XCTAssertEqual(msg, "val {-1} is less then zero")
        } catch { }

        do {
            try await { self.asyncFnThrows(val: 10) }
        } catch AsyncAwaitTestError.someError(let msg) {
            XCTAssertEqual(msg, "val {-1} is less then zero")
        } catch { }
    }

    func testSyncAwaitThrow() {
        do {
            let task = Async { try self.syncFnThrows(val: -2) }
            try await { task }
        } catch AsyncAwaitTestError.someError(let msg) {
            XCTAssertEqual(msg, "val {-2} is less then zero")
        } catch { }

        do {
            let task = Async { try self.syncFnThrows(val: 6) }
            try await { task }
        } catch AsyncAwaitTestError.someError(let msg) {
            XCTAssert(false)
        } catch {
            XCTAssert(false)
        }
    }

    func testAwaitAll() {
        let o1 = Async { self.soLongFn(val: 20) }
        let o2 = Async { self.soLongFn(val: 200) }

        let t1 = try! await { Task.WhenAll(o1, o2) }
        XCTAssertEqual(o1.returnValue?.0, 20)
        XCTAssertEqual(o2.returnValue?.0, 200)

        let o3 = Async { self.soLongFn(val: 30) }
        let o4 = Async { self.soLongFn(val: 600) }

        let t2 = try! Task.WaitAll(o3, o4)
        XCTAssertEqual(o3.returnValue?.0, 30)
        XCTAssertEqual(o4.returnValue?.0, 600)


        let o5 = Async { self.soLongFn(val: 20) }
        let o6 = Async { self.soLongFn(val: 200) }

        try! Task.WaitAll(o5, o6)
        XCTAssertEqual(o5.returnValue?.0, 20)
        XCTAssertEqual(o6.returnValue?.0, 200)
    }

    func testAwaitPending() {
        let queue = DispatchQueue(label: #function, qos: .userInitiated)

        let o1 = Async(on: queue, state: .pending) { self.soLongFn(val: 20) }
        o1.start()
        try! await { o1 }

        XCTAssertNotNil(o1.returnValue)
        XCTAssertEqual(o1.returnValue?.0, 20)
        XCTAssertEqual(o1.returnValue?.1, 40)
    }

    func testAwaitAny() {
        Async {
            let o1 = Async { self.soLongFn(val: 20) }
            let o2 = Async { self.soLongFn(val: 200) }

            let t1 = try! await { Task.WhenAny(o1, o2) }

            if t1 == o1 {
                XCTAssertNotNil(o1.returnValue)
            } else {
                XCTAssertNotNil(o2.returnValue)
            }

            let o3 = Async { self.soLongFn(val: 30) }
            let o4 = Async { self.soLongFn(val: 600) }

            let t2 = try! Task.WaitAny(o3, o4)

            if t2 == o3 {
                XCTAssertNotNil(o3.returnValue)
            } else {
                XCTAssertNotNil(o4.returnValue)
            }
        }
    }

    func testPromiseThenCatch() {
        let semaphore = DispatchSemaphore(value: 0)
        let p: Promise<Void> = Promise {
            throw AsyncAwaitTestError.someError("error from Promise")
            XCTAssert(false)
        }.then { (_) in
            XCTAssert(false)
        }.then { (_) in
            XCTAssert(false)
        }.catch { error in
            switch error {
                case AsyncAwaitTestError.someError(let msg):
                    XCTAssertEqual(msg, "error from Promise")
                default:
                    XCTAssert(false)
            }
            semaphore.signal()
        }

        XCTAssert(semaphore.wait(timeout: .now() + .seconds(1)) == .success)
    }

    func testPromiseThenFinally() {
        let semaphore = DispatchSemaphore(value: 0)

        let p = Promise {
            throw AsyncAwaitTestError.someError("some error")
            XCTAssert(false)
        }.then { (_) in
            XCTAssert(false)
        }.then { (_) in
            XCTAssert(false)
        }.finally {
            XCTAssert(true)
            semaphore.signal()
        }

        XCTAssert(semaphore.wait(timeout: .now() + .seconds(1)) == .success)
    }

    func testPromiseThen() {
        let expectation = self.expectation(description: "")
        expectation.expectedFulfillmentCount = 3

        let p = Promise {
            expectation.fulfill()
        }.then { (_) in
            expectation.fulfill()
        }.then { (_) in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1)
    }

    func testPromiseThenAllAny() {
        let semaphore = DispatchSemaphore(value: 0)

        let queue = DispatchQueue(label: #function, qos: .userInitiated)
        DispatchQueue.task = queue

        let all_1 = Promise() {}
        let all_2 = Promise() {}

        let any_1 = Promise() {}
        let any_2 = Promise() {}

        DispatchQueue.main.async {
            Promise<Bool> {
                true
            }.thenAll(
                    all_1,
                    all_2
            ).thenAny(
                    any_1,
                    any_2
            ).then {
                task in
                print(task)
                semaphore.signal()
            }
            semaphore.wait()
        }

    }

    func testAsyncNoDeallocUntilFulfilled() {

        weak var weakPromise1: Async<Int>?
        weak var weakPromise2: Async<Int>?

        autoreleasepool {
            XCTAssertNil(weakPromise1)
            XCTAssertNil(weakPromise2)
            weakPromise1 = Async<Int>(state: .pending) {
                task in
                task.result = 42
            }
            weakPromise2 = Async<Int>(state: .pending) {
                42
            }
            XCTAssertNotNil(weakPromise1)
            XCTAssertNotNil(weakPromise2)
        }

        XCTAssertNotNil(weakPromise1)
        XCTAssertNotNil(weakPromise2)

        weakPromise1?.start()
        weakPromise2?.start()
        try! weakPromise1?.await()
        try! weakPromise2?.await()

        let group = DispatchGroup()
        group.enter()

        DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + .seconds(5)) {
            group.leave()
        }

        group.wait()

        XCTAssertNil(weakPromise1)
        XCTAssertNil(weakPromise2)
    }


    func testPromiseMemoryLeak() {
        // Arrange.
        weak var weakPromise1: Promise<Int>?
        weak var weakPromise2: Promise<Int>?
        weak var weakPromise3: Promise<String>?

        // Act.
        autoreleasepool {
            XCTAssertNil(weakPromise1)
            XCTAssertNil(weakPromise2)
            XCTAssertNil(weakPromise3)
            weakPromise1 = Promise<Int> {
                task in
                task.result = 42
            }
            weakPromise2 = Promise<Int> {
                42
            }
            weakPromise3 = Promise<String> {
                "42"
            }
            XCTAssertNotNil(weakPromise1)
            XCTAssertNotNil(weakPromise2)
            XCTAssertNotNil(weakPromise3)
        }

        // Assert.
        XCTAssertNotNil(weakPromise1)
        XCTAssertNotNil(weakPromise2)
        XCTAssertNotNil(weakPromise3)

        weakPromise1?.then(weakPromise2!).then(weakPromise3!)

        let group = DispatchGroup()
        group.enter()

        DispatchQueue.global(qos: .background).asyncAfter(deadline: DispatchTime.now() + .seconds(1)) {
            group.leave()
        }

        group.wait()

        XCTAssertNil(weakPromise1)
        XCTAssertNil(weakPromise2)
        XCTAssertNil(weakPromise3)
    }

    static var allTests = [
        ("testAsyncAwait", testAsyncAwait),
        ("testSyncAwait", testSyncAwait),
        ("testAsyncAwaitThrow", testAsyncAwaitThrow),
        ("testSyncAwaitThrow", testSyncAwaitThrow),
        ("testAwaitAll", testAwaitAll),
        ("testAwaitPending", testAwaitPending),
        ("testAwaitAny", testAwaitAny),
        ("testPromiseThenCatch", testPromiseThenCatch),
        ("testPromiseThenFinally", testPromiseThenFinally),
        ("testPromiseThen", testPromiseThen),
        ("testPromiseThenAllAny", testPromiseThenAllAny),
        ("testAsyncNoDeallocUntilFulfilled", testAsyncNoDeallocUntilFulfilled),
        ("testPromiseMemoryLeak", testPromiseMemoryLeak)
    ]
}
