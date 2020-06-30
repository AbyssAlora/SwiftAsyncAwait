//
// Created by Abyss Alora on 13/06/2020.
//

import Foundation

extension Promise {
    func finally(_ callback: @escaping ()->()) -> Promise<Void> {
        provide(
                Promise<Void>(
                        on: self.dispatchQueue
                ) {
                    _ = try? self.await()
                    callback()
                }
        )
    }
}