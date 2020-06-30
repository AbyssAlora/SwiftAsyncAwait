//
// Created by Abyss Alora on 19/04/2020.
//

import Foundation

class AsyncTaskDispatchQueue {
    var queue: DispatchQueue = .global(qos: .background)
    static let `default` = AsyncTaskDispatchQueue()
}

extension DispatchQueue {
    static var task: DispatchQueue {
        get {
            AsyncTaskDispatchQueue.default.queue
        }
        set {
            AsyncTaskDispatchQueue.default.queue = newValue
        }
    }
}
