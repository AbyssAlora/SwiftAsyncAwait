//
// Created by Abyss Alora on 31/05/2020.
//

import Foundation

extension Promise {
    func thenAll(_ tasks: Task...) -> Promise<(Task, [Task])> {
        provide(
                Promise<(Task, [Task])> {
                    task in
                    try self.await()
                    for task in tasks { task.start() }
                    task.result = try Task.WaitAll(tasks)
                }
        )
    }
}

func all(_ tasks: Task...) -> Promise<(Task, [Task])> {
    Promise<(Task, [Task])> {
        task in
        for task in tasks { task.start() }
        task.result = try Task.WaitAll(tasks)
    }
}
