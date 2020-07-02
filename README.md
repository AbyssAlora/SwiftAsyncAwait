# SwiftAsyncAwait

It's just test implementation and some idea of the async/await mechanism in Swift.
This code is not tested in the real apps. If you want to use this code it's on your own risk yet. 
We will try make much better approach to async/await in the future if it's possible :-D. 

## Benchmark
Based on benchmark tests this library has pretty good performance. We comapred this library to GCD.
There were 10000 tests performed. As well as, th **SwiftAsyncAwait** is written on top of GCD. 
The data below was collected by running performance for Swift on an MacBook Pro. 
We tried build this library on top of `Operation` (which is also on top of GCD) but that was so slow.

- Average time in seconds needed to create a resolve one task on a serial queue (measured with 10,000 tries): 

<center>

|               | tests          | Avg. time (s)   |
| ------------- |:--------------:| ---------------:|
| GCD           | 10000          | 0.0000115612388 |
| AsyncAwait    | 10000          | 0.0000132883906 |
| Promises A/A  | 10000          | 0.0000131608975 |

</center>

- Average time in seconds needed to create 2 chained tasks on a serial queue (measured with 10,000 tries):

<center>

|               | tests          | Avg. time (s)   |
| ------------- |:--------------:| ---------------:|
| GCD           | 10000          | 0.0000148589611 |
| AsyncAwait    | 10000          | 0.0000170047283 |
| Promises A/A  | 10000          | 0.0000166108596 |

</center>

- Average time in seconds needed to create 3 chained tasks on a serial queue (measured with 10,000 tries):

<center>

|               | tests          | Avg. time (s)   |
| ------------- |:--------------:| ---------------:|
| GCD           | 10000          | 0.0000152180910 |
| AsyncAwait    | 10000          | 0.0000225465894 |
| Promises A/A  | 10000          | 0.0000185275519 |

</center>

- Total time in seconds needed to resolve 10,000 pending tasks with chained blocks and wait for control to get into 
each block on a concurrent queue:

<center>

|               | tests          | Avg. time (s)   |
| ------------- |:--------------:| ---------------:|
| GCD           | 10000          | 0.2285679578781 |
| AsyncAwait    | 10000          | 0.2380779981613 |
| Promises A/A  | 10000          | 0.2366579961777 |

</center>

- Total time in seconds needed to create and await 2 of 3 tasks (measured with 10,000 tries):

<center>

|               | tests          | Avg. time (s)   |
| ------------- |:--------------:| ---------------:|
| GCD           | 10000          | 0.0000336177230 |
| AsyncAwait    | 10000          | 0.0000406291962 |

</center>


## Usage
Usage of this library is simple. You can define functions as **Async** and **await** them if needed.
As well as you can run existing sync functions as **Async**. Examples are simple, but it's 
better approach to call **await** in Async block, **not on the main thread** because you'll block main
thread for a while. Each function in Async block is called on the `DispatchQueue.task`, as well as the 
functions with completion handler.


### Create Async function from sync one

You can run a synchronous method as asynchronous with few lines of code:
```swift
func mySyncFunction() -> Int {
    // Do whatever you want
    return 1
}

let task = Async { mySyncFunction() }
let result = try! await { task }
```

### Run bunch of code asynchronously

As well as, you can run code asynchronously:

```swift
Async {
    for _ in 0...100 {
        print("♥️")
    }
}
```

### Create asynchronous function in definition

If you want to create asynchronous function and/or await.

```swift
func getUserData() -> Async<(UserData, Error)> {
    Async { task in 
        // Do whatever you want
        task.result = (data, error)
    }
}

let (data, error) = try! await { getUserData() }
```

If `task.result` is set, then `await`/`wait` will return data from `getUserData()` function. 
You have to set `task.result` if await timeout is not set, because you'll go to dead lock.

### Await more tasks at once

You can await more Async functions at once if it's needed. 

```swift
func a() -> Async<String> { 
    Async { task in 
        task.result = "hello from a"
    } 
}

func b() -> Async<(Int, Double)> { 
    Async { task in 
        task.result = (0, 1.9)
    } 
}

let taskA = a()
let taskB = b() 

let first = try! await { Task.WhenAll(taskA, taskB) } 

if(taskA == first) {
    print ("taskA is finished first with ", taskA.result)
} else if (taskB == first) {
    print ("taskB is finished first with ", taskB.result)
}
```

or you can use wrapper

```swift
let first = try! Task.WaitAll(taskA, taskB)
```

### Await if any task is finished

This section is similar as above with difference, that if thread is blocked until one of 
the tasks is finished.

```swift
func a() -> Async<String> { 
    Async { task in 
        task.result = "hello from a"
    } 
}

func b() -> Async<(Int, Double)> { 
    Async { task in 
        task.result = (0, 1.9)
    } 
}

let taskA = a()
let taskB = b() 

let finished = try! await { Task.WhenAny(taskA, taskB) } 

if(taskA == finished) {
    print ("taskA is finished with ", taskA.result)
} else if (taskB == finished) {
    print ("taskB is finished with ", taskB.result)
}
```

or you can use wrapper

```swift
let finished = try! Task.WaitAny(taskA, taskB)
```

### Await with timeout

If we want to define max timeout of the await (max time for blocking thread), we can call await with 
timeout parameter.

```swift
let (data, error) = try! await(timeout: .seconds(1)) { getUserData() }
```

### Handle Errors

This library brings functionality of standard try/catch error handling. Error is handled by await function. As well as, you
can check `error` value of your task or pass error as generic parameter (see `getUserData()` example)

```swift
enum DotError: Error {
    case lessThanZeroError(String)
}

func printDots(_ n: Int) -> Async<(Int, String)> {
    Async {
        if (n < 0) {
            throw DotError.lessThanZeroError("N is less than 0!")
        } 

        for _ in 0...n {
            print("\(n) x ⚪️️")
        }
        
        return (n, "Dots printed!!!")
    }
}

do {
    let task = printDots(-1)
    let result = try await { task }
} catch DotError.lessThanZeroError(let msg) {
    print(msg)
} catch { 
    // Default catch
}
```
Because of error handling, you have to always call `await` function with `try` keyword. 

### Attempts (retry) and delay
You can use attempts and delay. Delay means, that Async task will start after time defined as delay.
Attemts is number of repetitions if task finished with error or **retry** in other words.

```swift
func asyncFunctionWithThrow() -> Async<Void> {
    Async(delay: .seconds(1), attempts: 4) {
        throw AsyncTestError.runtimeError("Error passed from Async task")
    }
}

func testAsyncAwait_attempts_delay() {
    do {
        try await { self.asyncFunctionWithThrow() }
    } catch AsyncTestError.runtimeError(let msg) {
        print(msg)
    } catch { }
}
```

### Task states

Task object has more states and some of them will be updated in the future:
- `.pending`  defines that task is prepared and waiting for run (default state)
- `.running`  defines that task is actually running 
- `.waiting` signalize that task is running, but another task is also waiting for result.
- `.finished` defines that task was resolved and return values of task are available in `task.result` 
(or `task.returnValue` for `Async<...>`)
- `.finishedWithError` defines that task is finished but `task.result` will be probably `nil` and `task.error` 
was fulfilled


### Create Async with pending state

**We have to notice, that Task is alive until task is not finished. This means, that start or 
resolve pending task is needed!** 
State of the `Task` object is `.pending` on default. Byt `Async<...>` is designed to force `.running` state with
 `start()` on initialization and Async task will start immediately. If you want to create `Async<...>` with 
pending state, just define state in `init(...)`:

```swift
let task = Async(state: .pending) { 10 }
```

now the `task` won't start immediately. If you want to start `task` just call:

```swift
task.start()
```

### Run specific Async task on different Queue
You can specify `DispatchQueue` for your Async task.

```swift
func customQueueAsyncTask() -> Async<Int> {
    Async(on: .global()) {
        // Do whatever you want
        return 1
    }
}

let value = try! await { customQueueAsyncTask() }
```

### Change DispatchQueue

If you want to change default `DispatchQueue` for running tasks you can set:

```swift
DispatchQueue.task = DispatchQueue(label: "MyDispatchQueue", qos: .userInitiated, attributes: .concurrent)
```

`DispatchQueue.task` should be concurrent.

### Promises

We made class `Promise` which extends from `Async`. It's because somebody prefers promises like
syntax. **WARNING: Promise is created with `.pending` state and it's fired when you call `then`, `catch` or
`finally`. If you want to create just single async block just use `Async`.**

```swift
Promise(on: someQueue) {
    // do something
    return 1
}.then {
    (number) in 
    // do something
    return [1, 2]
}.then {
    numbers in 
    return "Hello from promises \(numbers[0]) and \(numbers[1])"
}.then {
    (msg) in 
    print(msg)
}.catch {
    error in 
    print(error)
}.finlly {
    // Do something no matter whats happend
}
```

Completions are automatically transfer to promises and they await parent asynchronously. 
As well as you can define completions as functions:

```swift
func f_promise2(number: Int) -> [Int] { 
    [number, 2] 
}

func f_promise3(numbers: [Int]) -> String { 
    "Hello from promises \(numbers[0]) and \(numbers[1])" 
}

func f_promise4(msg: String) {
    print(msg)
}

Promise(on: someQueue) {
    return 1
}.then(
    f_promise2
).then(
    f_promise3
).then(
    f_promise4
).catch {
    error in 
    print(error)
}.finlly {
    // Do something no matter whats happend
}

```

Finally you can pass promise into `then` function or function with Promise return type. 

Contributing
------

Contribution is welcome.

Contributors: [@drago19sk](https://github.com/drago19sk) [@SlaveMast3r](https://github.com/SlaveMast3r)

Licence
------

MIT
