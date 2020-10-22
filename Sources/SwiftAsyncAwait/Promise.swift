//
// Created by Abyss Alora on 27/05/2020.
//

import Foundation


public class Promise<Result>: Async<Result> {

    private override init(
            on dispatchQueue: DispatchQueue? = nil,
            delay: DispatchTimeInterval? = nil,
            attempts: Int = 0,
            state: TaskState = .running,
            _ f: @escaping () throws ->(Result)) {
        super.init()
    }

    private override init(
            on dispatchQueue: DispatchQueue? = nil,
            delay: DispatchTimeInterval? = nil,
            attempts: Int = 0,
            state: TaskState = .running,
            _ f: @escaping (Async<Result>) throws -> ()) {
        super.init()
    }

    public init(
            on dispatchQueue: DispatchQueue? = nil,
            delay: DispatchTimeInterval? = nil,
            attempts: Int = 0,
            _ f: @escaping () throws ->(Result)) {
        super.init(on: dispatchQueue, delay: delay, attempts: attempts, state: .pending, f)
    }

    public init(
            on dispatchQueue: DispatchQueue? = nil,
            delay: DispatchTimeInterval? = nil,
            attempts: Int = 0,
            _ f: @escaping (Async<Result>) throws -> ()) {
        super.init(on: dispatchQueue, delay: delay, attempts: attempts, state: .pending, f)
    }

    internal func provide<U>(_ promise: Promise<U>) -> Promise<U> {
        self.start()
        promise.start()
        return promise
    }
}
