//
// Created by Abyss Alora on 05/05/2020.
//

import Foundation

extension Task {
    final class WhenAny: Async<Task>, TaskDelegate {

        /**
             Constructor

             - Parameters:
                - *tasks*: array of tasks for waiting
         */
        init(_ tasks: Task...) {
            super.init()
            self.initialize(tasks)
        }

        /**
            Same as constructor init(_ tasks: Task...) but this is deifined because of *bug?*
        */
        init(_ tasks: [Task]) {
            super.init()
            self.initialize(tasks)
        }

        private func initialize(_ tasks: [Task]) {
            self.start()
            for task in tasks { // lets set delegate of all tasks to self, because we want to know when first is finished
                task.delegate = self
            }
        }

        func finishedWith(_ result: Task?) {
            // when some task is finished set the result as first finished task or set the error
            if let error = result?.error {
                self.error = error
            }
            self.result = result
        }
    }
}
