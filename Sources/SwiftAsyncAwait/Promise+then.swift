//
// Created by Abyss Alora on 13/06/2020.
//

import Foundation

extension Promise {

    func then<U>(
            on dispatchQueue: DispatchQueue? = nil,
            delay: DispatchTimeInterval? = nil,
            attempts: Int = 0,
            _ callback: @escaping (Result) throws -> U
    ) -> Promise<U> {
        provide(
                Promise<U>(
                        on: dispatchQueue ?? self.dispatchQueue,
                        delay: delay,
                        attempts: attempts
                ) {
                    [self] in
                    try self.await()
                    return try callback(self.returnValue!)
                }
        )
    }

    func then<U>(
            on dispatchQueue: DispatchQueue? = nil,
            delay: DispatchTimeInterval? = nil,
            attempts: Int = 0,
            _ callback: @escaping (Promise<Result>) -> Promise<U>
    ) -> Promise<U> {
        provide(
                callback(self)
        )
    }

    func then<U>(
            on dispatchQueue: DispatchQueue? = nil,
            delay: DispatchTimeInterval? = nil,
            attempts: Int = 0,
            _ callback: @escaping (Result) -> Promise<U>
    ) -> Promise<U> {
        provide(
                Promise<U>(
                        on: dispatchQueue ?? self.dispatchQueue,
                        delay: delay,
                        attempts: attempts
                ) {
                    [self] task in
                    try self.await()
                    let promise = callback(self.returnValue!)
                    try promise.work(on: task)
                    promise.result = nil
                }
        )
    }

    func then<U>(
            on dispatchQueue: DispatchQueue? = nil,
            delay: DispatchTimeInterval? = nil,
            attempts: Int = 0,
            _ promise: Promise<U>
    ) -> Promise<U> {
        provide(
                Promise<U>(
                        on: dispatchQueue ?? self.dispatchQueue,
                        delay: delay,
                        attempts: attempts
                ) {
                    [self] task in
                    try self.await()
                    try promise.work(on: task)
                    promise.result = nil // set the result to nil for allow deallocation
                }
        )
    }
}