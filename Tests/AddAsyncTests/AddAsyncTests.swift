import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import AddAsyncMacros

let testMacros: [String: Macro.Type] = [
    "AddAsync": AddAsyncMacro.self,
]

final class AddAsyncTests: XCTestCase {
    
    // Test 1: Standard Function (Implementation) -> Generates Body
    func testResultMacro() throws {
        assertMacroExpansion(
            """
            @AddAsync
            func fetch(completion: @escaping (Result<String, Error>) -> Void) {
                print("fetching")
            }
            """,
            expandedSource: """
            func fetch(completion: @escaping (Result<String, Error>) -> Void) {
                print("fetching")
            }
            
            func fetch() async throws -> String {
                var hasResumed = false
                return try await withCheckedThrowingContinuation { continuation in
                    fetch() { result in
                        guard !hasResumed else {
                            return
                        }
                        hasResumed = true
                        continuation.resume(with: result)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 2: Protocol Requirement -> Generates Signature Only (No Body)
    func testProtocolRequirement() throws {
        assertMacroExpansion(
            """
            protocol NetworkService {
                @AddAsync
                func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void)
            }
            """,
            expandedSource: """
            protocol NetworkService {
                func fetchUser(id: String, completion: @escaping (Result<User, Error>) -> Void)
            
                func fetchUser(id: String) async throws -> User
            }
            """,
            macros: testMacros
        )
    }
    
    // Test 3: Generic Optional -> Generates Body
    func testGenericOptionalMacro() throws {
        assertMacroExpansion(
            """
            @AddAsync
            func fetch<T: Model>(with router: BaseRouter, type: FetchType, completion: @escaping ((T?) -> Void)) {
                print("fetching generic")
            }
            """,
            expandedSource: """
            func fetch<T: Model>(with router: BaseRouter, type: FetchType, completion: @escaping ((T?) -> Void)) {
                print("fetching generic")
            }
            
            func fetch<T: Model>(with router: BaseRouter, type: FetchType) async -> T? {
                var hasResumed = false
                return await withCheckedContinuation { continuation in
                    fetch(with: router, type: type) { value in
                        guard !hasResumed else {
                            return
                        }
                        hasResumed = true
                        continuation.resume(returning: value)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
}
