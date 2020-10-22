//
// Created by Abyss Alora on 07/05/2020.
//

import Foundation

public extension Task {
    @discardableResult
    static func WaitAll(_ tasks: Task...) throws -> (Task, [Task])? {
        try await { Task.WhenAll(tasks) }
    }

    @discardableResult
    static func WaitAll(_ tasks: [Task]) throws -> (Task, [Task])? {
        try await { Task.WhenAll(tasks) }
    }
}
