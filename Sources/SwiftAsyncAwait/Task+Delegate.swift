//
// Created by Abyss Alora on 26/04/2020.
//

import Foundation

protocol TaskDelegate: NSObjectProtocol {
    func finishedWith(_ result: Task?)
}