/// Generates an async/throws version of a function that takes a completion handler.
///
/// Supports:
/// - Result<T, Error> -> async throws -> T
/// - T? -> async -> T?
@attached(peer, names: overloaded)
public macro AddAsync() = #externalMacro(module: "AddAsyncMacros", type: "AddAsyncMacro")
