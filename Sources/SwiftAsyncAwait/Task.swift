//
// Created by Abyss Alora on 26/04/2020.
//

import Foundation

public class Task: NSObject {
    private var pendingTask: Task? // Create retain cycle, because we want to keep Task alive until result is resolved

    var dispatchQueue: DispatchQueue = DispatchQueue.task // the main function will be executed on this queue
    internal var dispatchSemaphore = DispatchSemaphore(value: 0) // semaphore for await mechanism (signal when task.result is fulfilled)

    private var delay: DispatchTimeInterval? // delay for execution main function
    private var attempts: Int = 0 // retry until attempts reach 0 value
    private(set) public var state: TaskState = .pending // actual state of current task

    /**
         Delegate for notification when task.state was changed to `.finished` or `.finishedWithError`
     */
    public weak var delegate: TaskDelegate? {
        didSet {
            if self.state.didFinish { self.delegate?.finishedWith(self) }
        }
    }

    /**
         some Error if task finished with error
     */
    public var error: Error? {
        didSet {
            if self.attempts > 0 { // retry
                self.state = .retry
                self.attempts -= 1
                self.start() // start task again
            } else {
                if !self.state.didFinish { // if task wasn't finished yet
                    self.state = .finishedWithError
                    self._result = nil
                    self.dispatchSemaphore.signal() // signal semaphore for release
                    self.delegate?.finishedWith(self) // notify delegate that current task finished
                    self.pendingTask = nil // clear retain cycle
                }
            }
        }
    }

    private var _result: Any?
    /**
         Result of the task
     */
    public var result: Any? {
        get {
            self._result
        }
        set(newValue) {
            if !self.state.didFinish { // same logic as error
                self._result = newValue
                self.state = .finished
                self.dispatchSemaphore.signal()
                self.delegate?.finishedWith(self)
                self.pendingTask = nil
            }
        }
    }

    /**
         Wait for resolve the `result` if function is not in `.running` state.

         - Throws:
            - `Error`: some user defined error for error handling

         - Returns: result as Any?.
     */
    @discardableResult
    final public func wait() throws -> Any? {
        if !self.state.isRunning {
            if let error = self.error {
                throw error
            }
            return self.result
        }

        self.dispatchSemaphore.wait()
        if let error = self.error {
            throw error
        }
        return self.result
    }

    /**
         Wait for resolve the `result` until timeout is reached if function is not in `.running` state.

         - Parameters:
            - *timeout*: Maximum time for waiting to resolve the result

         - Throws:
            - `Error`: some user defined error for error handling

         - Returns: result as Any?.
     */
    @discardableResult
    final public func wait(timeout: DispatchTimeInterval) throws -> Any? {
        if !self.state.isRunning {
            if let error = self.error {
                throw error
            }
            return self.result
        }

        _ = self.dispatchSemaphore.wait(timeout: DispatchTime.now() + timeout)
        if let error = self.error {
            throw error
        }
        return self.result
    }

    /**
         Constructor

         - Parameters:
            - *dispatchQueue*: The dispatch queue for execution of the main function.
            - *delay*: Defines time for delaying execution of the main function
            - *attempts*: If main function throws error the Task will retry execution of the main function until attempts reach 0
     */
    public init(
            on dispatchQueue: DispatchQueue? = nil,
            delay: DispatchTimeInterval? = nil,
            attempts: Int = 0
    ) {
        super.init()

        self.pendingTask = self // keep strong reference until result is set

        if let dispatchQueue = dispatchQueue {
            self.dispatchQueue = dispatchQueue
        }
        self.delay = delay
        self.attempts = attempts
    }

    /**
         Async function body

         - Throws: `Error`: some user defined error for error handling
     */
    internal func main() throws { }

    /**
         This function is responsible for run the async body or handle an error
    */
    final private func execute() {
        do {
            try self.main()
        } catch let error {
            self.error = error
        }
    }

    /**
         If can start, this func fire the async body trough execute() in defined thread
     */
    final public func start() {
        if !self.state.canStart { return }
        self.state = .running
        if let delay = self.delay {
            self.dispatchQueue.asyncAfter(deadline: DispatchTime.now() + delay) {
                self.execute()
            }
        } else {
            self.dispatchQueue.async {
                self.execute()
            }
        }
    }
}

