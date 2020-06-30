//
// Created by Abyss Alora on 13/06/2020.
//

import Foundation

extension Promise {
    func `catch`(_ callback: @escaping (Error)->()) -> Promise<Void> {
        provide(
                Promise<Void>(
                        on: self.dispatchQueue
                ) {
                    do {
                        try self.await()
                    } catch {
                        callback(error)
                    }
                }
        )
    }
}