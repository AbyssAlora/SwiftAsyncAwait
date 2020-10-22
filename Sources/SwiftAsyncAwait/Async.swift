//
// Created by Abyss Alora on 16/04/2020.
//

import Foundation

public class Async<Result>: Task {

    private var  f: (() throws -> (Result))?
    private var _f: ((Async<Result>) throws -> ())?

    var returnValue: Result? {
        self.result as? Result
    }

    @discardableResult
    func await() throws -> Result? {
        try self.wait() as? Result
    }

    @discardableResult
    func await(timeout: DispatchTimeInterval) throws -> Result? {
        try self.wait(timeout: timeout) as? Result
    }

    init() {
        super.init()
    }

    init(
            on dispatchQueue: DispatchQueue? = nil,
            delay: DispatchTimeInterval? = nil,
            attempts: Int = 0,
            state: TaskState = .running,
            _ f: @escaping () throws ->(Result)) {

        super.init(on: dispatchQueue, delay: delay, attempts: attempts)
        self.f = f
        if state != .pending {
            self.start()
        }
    }

    init(
            on dispatchQueue: DispatchQueue? = nil,
            delay: DispatchTimeInterval? = nil,
            attempts: Int = 0,
            state: TaskState = .running,
            _ f: @escaping (Async<Result>) throws -> ()) {

        super.init(on: dispatchQueue, delay: delay, attempts: attempts)
        self._f = f
        if state != .pending {
            self.start()
        }
    }

    override func main() throws {
        if let f = self.f {
            self.result = try f()
        } else if let f = self._f {
            try f(self)
        }
    }

    func work(on async: Async<Result>) throws {
        if let f = self.f {
            async.result = try f()
        } else if let f = self._f {
            try f(async)
        }
    }
}
