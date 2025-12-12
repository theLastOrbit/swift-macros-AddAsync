import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest
import AddAsyncMacros

let testMacros: [String: Macro.Type] = [
    "AddAsync": AddAsyncMacro.self,
]

final class AddAsyncTests: XCTestCase {
    
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
                return try await withCheckedThrowingContinuation { continuation in
                    fetch() { result in
                        continuation.resume(with: result)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
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
                return await withCheckedContinuation { continuation in
                    fetch(with: router, type: type) { value in
                        continuation.resume(returning: value)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
    
    func testGenericArrayMacro() throws {
        assertMacroExpansion(
            """
            @AddAsync
            func fetchWithAuth<T: Model>(with router: BaseRouter, type: FetchType, completion: @escaping (([T]?) -> Void)) {
                 print("fetching list")
            }
            """,
            expandedSource: """
            func fetchWithAuth<T: Model>(with router: BaseRouter, type: FetchType, completion: @escaping (([T]?) -> Void)) {
                 print("fetching list")
            }
            
            func fetchWithAuth<T: Model>(with router: BaseRouter, type: FetchType) async -> [T]? {
                return await withCheckedContinuation { continuation in
                    fetchWithAuth(with: router, type: type) { value in
                        continuation.resume(returning: value)
                    }
                }
            }
            """,
            macros: testMacros
        )
    }
}
