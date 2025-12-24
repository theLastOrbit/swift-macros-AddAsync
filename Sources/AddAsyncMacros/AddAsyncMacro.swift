import SwiftSyntax
import SwiftSyntaxMacros
import SwiftSyntaxBuilder

public struct AddAsyncMacro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        
        // 1. Ensure it's a function
        guard let funcDecl = declaration.as(FunctionDeclSyntax.self) else {
            throw CustomError.message("@AddAsync only works on functions.")
        }
        
        // 2. Extract basic function info
        let funcName = funcDecl.name.text
        let params = funcDecl.signature.parameterClause.parameters
        let modifiers = funcDecl.modifiers.description
        
        // 3. Extract Generics
        let genericClause = funcDecl.genericParameterClause?.description ?? ""
        let whereClause = funcDecl.genericWhereClause.map { " \($0.description)" } ?? ""
        
        // 4. Check if this is a Protocol Requirement (No Body)
        let isProtocolRequirement = funcDecl.body == nil
        
        // 5. Find the completion handler
        guard let completionParam = params.last else {
            throw CustomError.message("Function must have parameters.")
        }
        
        // --- TYPE PARSING ---
        var typeToCheck = completionParam.type
        if let attributedType = typeToCheck.as(AttributedTypeSyntax.self) { typeToCheck = attributedType.baseType }
        if let tupleType = typeToCheck.as(TupleTypeSyntax.self), let first = tupleType.elements.first { typeToCheck = first.type }
        
        guard let completionType = typeToCheck.as(FunctionTypeSyntax.self) else {
            throw CustomError.message("Last parameter must be a closure.")
        }
        
        guard let completionInputType = completionType.parameters.first?.type else {
            throw CustomError.message("Completion closure must take exactly one argument.")
        }
        
        var returnType: TypeSyntax
        var isResult = false
        
        if let identifierType = completionInputType.as(IdentifierTypeSyntax.self),
           identifierType.name.text == "Result",
           let genericArgs = identifierType.genericArgumentClause?.arguments,
           let successType = genericArgs.first?.argument {
            returnType = successType
            isResult = true
        } else {
            returnType = completionInputType
            isResult = false
        }
        
        // 6. Clean Parameters (Remove completion + trailing comma)
        let paramsToKeep = Array(params.dropLast())
        let newParamsString = paramsToKeep.enumerated().map { index, param in
            var p = param
            if index == paramsToKeep.count - 1 { p.trailingComma = nil }
            return p.description
        }.joined()
        
        // 7. Generate Code
        
        // CASE A: Protocol Requirement (Generate Signature ONLY)
        if isProtocolRequirement {
            if isResult {
                return [
                    "\(raw: modifiers)func \(raw: funcName)\(raw: genericClause)(\(raw: newParamsString)) async throws -> \(returnType)\(raw: whereClause)"
                ]
            } else {
                return [
                    "\(raw: modifiers)func \(raw: funcName)\(raw: genericClause)(\(raw: newParamsString)) async -> \(returnType)\(raw: whereClause)"
                ]
            }
        }
        
        // CASE B: Implementation (Generate Body)
        let callArguments = params.dropLast().map { param in
            let label = param.firstName.text != "_" ? "\(param.firstName.text): " : ""
            return "\(label)\(param.secondName?.text ?? param.firstName.text)"
        }.joined(separator: ", ")
        
        if isResult {
            return [
                """
                \(raw: modifiers)func \(raw: funcName)\(raw: genericClause)(\(raw: newParamsString)) async throws -> \(returnType)\(raw: whereClause) {
                    var hasResumed = false
                    return try await withCheckedThrowingContinuation { continuation in
                        \(raw: funcName)(\(raw: callArguments)) { result in
                            guard !hasResumed else {
                                return 
                            }
                            hasResumed = true
                            continuation.resume(with: result)
                        }
                    }
                }
                """
            ]
        } else {
            return [
                """
                \(raw: modifiers)func \(raw: funcName)\(raw: genericClause)(\(raw: newParamsString)) async -> \(returnType)\(raw: whereClause) {
                    var hasResumed = false
                    return await withCheckedContinuation { continuation in
                        \(raw: funcName)(\(raw: callArguments)) { value in
                            guard !hasResumed else { 
                                return 
                            }
                            hasResumed = true
                            continuation.resume(returning: value)
                        }
                    }
                }
                """
            ]
        }
    }
}

enum CustomError: Error, CustomStringConvertible {
    case message(String)
    var description: String {
        switch self {
        case .message(let string):
            return string
        }
    }
}
