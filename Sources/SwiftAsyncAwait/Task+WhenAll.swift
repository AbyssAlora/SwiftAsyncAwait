import Foundation

extension Task {
    final class WhenAll: Async<(Task, [Task])>, TaskDelegate {
        private var tasks: [Task] = []

        override func await() throws -> (Task, [Task])? {
            for task in self.tasks {
                try task.wait()
            }
            return self.result as? (Task, [Task])
        }

        override func await(timeout: DispatchTimeInterval) throws -> (Task, [Task])? {
            for task in self.tasks {
                try task.wait(timeout: timeout)
            }
            return self.result as? (Task, [Task])
        }

        init(_ tasks: Task...) {
            super.init()
            self.initialize(tasks)
        }

        init(_ tasks: [Task]) {
            super.init()
            self.initialize(tasks)
        }

        private func initialize(_ tasks: [Task]) {
            self.start()
            self.tasks = tasks
            for task in self.tasks {
                task.delegate = self
            }
        }

        func finishedWith(_ result: Task?) {
            self.result = (result, self.tasks)
        }

        deinit {
            self.tasks.removeAll()
        }
    }
}