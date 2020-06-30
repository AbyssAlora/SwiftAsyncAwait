//
// Created by Abyss Alora on 07/05/2020.
//

import Foundation

enum TaskState: Int {
    case running, finished, pending, finishedWithError, retry

    var didFinish: Bool {
        self == .finished || self == .finishedWithError
    }

    var canStart: Bool {
        self == .pending || self == .retry
    }

    var isRunning: Bool {
        self == .running
    }
}
