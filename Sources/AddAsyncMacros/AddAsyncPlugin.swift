import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct AddAsyncPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        AddAsyncMacro.self,
    ]
}
