//
// Created by Abyss Alora on 31/05/2020.
//

import Foundation

extension Promise {
    func thenAny(_ tasks: Task...) -> Promise<Task> {
        provide(
                Promise<Task> {
                    task in
                    try self.await()
                    for task in tasks { task.start() }
                    task.result = try Task.WaitAny(tasks)
                }
        )
    }
}

func any(_ tasks: Task...) -> Promise<Task> {
    Promise<Task> {
        task in
        for task in tasks { task.start() }
        task.result = try Task.WaitAny(tasks)
    }
}
