//
// Created by Abyss Alora on 20/04/2020.
//

import Foundation

@discardableResult
func await<T>(_ task: () -> Async<T>) throws -> T? {
    try task().await()
}

@discardableResult
func await<T>(timeout: DispatchTimeInterval, _ task: () -> Async<T>) throws -> T? {
    try task().await(timeout: timeout)
}


