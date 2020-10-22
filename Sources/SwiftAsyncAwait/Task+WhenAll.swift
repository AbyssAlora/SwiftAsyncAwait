import Foundation

public extension Task {
    final class WhenAll: Async<(Task, [Task])>, TaskDelegate {
        private var tasks: [Task] = []

        override public func await() throws -> (Task, [Task])? {
            for task in self.tasks {
                try task.wait()
            }
            return self.result as? (Task, [Task])
        }

        override public func await(timeout: DispatchTimeInterval) throws -> (Task, [Task])? {
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

        public func finishedWith(_ result: Task?) {
            self.result = (result, self.tasks)
        }

        deinit {
            self.tasks.removeAll()
        }
    }
}