# AddAsync

[![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)]()
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20macOS%20%7C%20watchOS%20%7C%20tvOS-lightgrey.svg)]()
[![License](https://img.shields.io/badge/License-MIT-blue.svg)]()

**AddAsync** is a Swift Macro that automatically generates `async`/`await` versions of your legacy completion-handler functions.

Stop writing boilerplate `withCheckedContinuation` wrappers manually. Let the compiler do it for you safely and cleanly.

## Features

- ✅ **Zero Runtime Overhead:** All code is generated at compile time.
- ✅ **Protocol Support:** Works on protocol definitions (generates async signatures without bodies).
- ✅ **Smart Detection:** Automatically detects if the function should throw errors (for `Result` types) or just return values.
- ✅ **Generic Support:** Works perfectly with `<T: Model>`, arrays `[T]`, and complex signatures.

---

## Installation

### Xcode (SPM)

1.  Go to **File > Add Package Dependencies...**
2.  Enter the URL of your repository:
    ```
    https://github.com/theLastOrbit/swift-macros-AddAsync.git
    ```
3.  Click **Add Package**.

### Package.swift

Add it to your `dependencies` in `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/theLastOrbit/swift-macros-AddAsync.git", from: "1.1.0")
]
```

Then add `"AddAsync"` to your target's dependencies.

---

## Usage

Simply attach `@AddAsync` to any function that accepts a completion handler as its last parameter.

### 1. Result Types (Async + Throws)

If your completion handler returns a `Result<T, Error>`, the generated function will be `async throws` and return the success type `T`.

**Code:**

```swift
import AddAsync

@AddAsync
func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void) {
    // Legacy code logic...
}
```

**Generated Peer Function (Invisible):**

```swift
func fetchUser(id: String) async throws -> User {
    return try await withCheckedThrowingContinuation { continuation in
        fetchUser(id: id) { result in
            continuation.resume(with: result)
        }
    }
}
```

### 2. Protocols (Signatures Only)

You can use `@AddAsync` in protocols. It will generate the `async` requirement signature automatically.

**Code:**

```swift
protocol NetworkService {
    @AddAsync
    func fetchConfig(completion: @escaping (Result<Config, Error>) -> Void)
}
```

**Generated Requirement (Invisible):**

```swift
protocol NetworkService {
    func fetchConfig(completion: @escaping (Result<Config, Error>) -> Void)

    // Generated:
    func fetchConfig() async throws -> Config
}
```

### 3. Generics & Optionals

If your completion handler returns a standard value (like `T?` or `[T]?`), the generated function will be `async` (non-throwing) and preserve all generic constraints.

**Code:**

```swift
@AddAsync
func fetch<T: Model>(with router: BaseRouter, completion: @escaping (T?) -> Void) {
    // Legacy code logic...
}
```

**Generated Peer Function (Invisible):**

```swift
func fetch<T: Model>(with router: BaseRouter) async -> T? {
    return await withCheckedContinuation { continuation in
        fetch(with: router) { value in
            continuation.resume(returning: value)
        }
    }
}
```

---

## Requirements

- Swift 5.9+ (Xcode 15+)
- iOS 13.0+ / macOS 10.15+ (Backward compatible runtime)

## License

This library is released under the MIT License. See [LICENSE](LICENSE) for details.

**Inspiration:**
Got the inspiration to make this library:

- From [this Linkedin post](https://www.linkedin.com/posts/hirrsalim_swift-iosdev-swiftmacros-activity-7386297904069492736-k7kR/) of Hirra Salim
- Also from [this awesome git repo](https://github.com/francescoleoni98/Swift-Macros-AddAsync-example)
