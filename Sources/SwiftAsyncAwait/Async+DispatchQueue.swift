//
// Created by Abyss Alora on 19/04/2020.
//

import Foundation

public class AsyncTaskDispatchQueue {
    var queue: DispatchQueue = DispatchQueue.global(qos: .userInitiated)
    static let `default` = AsyncTaskDispatchQueue()
}

public extension DispatchQueue {
    static var task: DispatchQueue {
        get {
            AsyncTaskDispatchQueue.default.queue
        }
        set {
            AsyncTaskDispatchQueue.default.queue = newValue
        }
    }
}
