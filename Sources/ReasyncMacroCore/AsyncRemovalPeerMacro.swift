//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import SwiftDiagnostics
import SwiftSyntax
import SwiftSyntaxMacros



package protocol AsyncRemovalPeerMacro: PeerMacro { }

extension AsyncRemovalPeerMacro
{
    /// Expands an attached macro to introduce peer declarations that exist
    /// alongside the given declaration.
    /// - Parameters:
    ///   - node: The custom attribute describing the attached macro.
    ///   - declaration: The declaration to which the macro attribute is
    ///   attached.
    ///   - context: The context in which to perform the macro expansion.
    /// - Returns: The set of peer declarations.
    public static func expansion(
        of                  node        : AttributeSyntax,
        providingPeersOf    declaration : some DeclSyntaxProtocol,
        in                  context     : some MacroExpansionContext
    ) throws -> [DeclSyntax]
    {
        guard let function = declaration.as(FunctionDeclSyntax.self)
        else
        {
            context.diagnose(Diagnostic(
                node:       node,
                message:    AsyncRemovalDiagnosticKind.reasyncOnNonFunction
            ))

            return []
        }
        
        guard function.signature.effectSpecifiers?.asyncSpecifier != nil
        else
        {
            context.diagnose(Diagnostic(
                node:       node,
                message:    AsyncRemovalDiagnosticKind.requiresAsync
            ))
            
            return []
        }
        
        guard !context.lexicalContext
            .contains(where: { $0.is(ProtocolDeclSyntax.self) })
        else
        {
            context.diagnose(Diagnostic(
                node:       node,
                message:    AsyncRemovalDiagnosticKind.reasyncOnProtocolRequirement
            ))
            
            return []
        }
        
        
        
        let rewriter = AsyncRemovalRewriter(
            rootFunction:   function,
            context:        context
        )
        
        let rewritten = rewriter
            .rewrite(function)
            .cast(FunctionDeclSyntax.self)
        
        guard let prefix: TriviaPiece = function.leadingIndentationPrefix
        else
        {
            return [DeclSyntax(rewritten)]
        }
        
        let normalized: FunctionDeclSyntax
            = IndentationTrimmingRewriter(prefix: prefix)
                .rewrite(rewritten)
                .cast(FunctionDeclSyntax.self)
        
        return [DeclSyntax(normalized)]
    }
}
