//
// Created by Abyss Alora on 07/05/2020.
//

import Foundation

public extension Task {
    @discardableResult
    static func WaitAny(_ tasks: Task...) throws -> Task? {
        try await { Task.WhenAny(tasks) }
    }

    @discardableResult
    static func WaitAny(_ tasks: [Task]) throws -> Task? {
        try await { Task.WhenAny(tasks) }
    }
}