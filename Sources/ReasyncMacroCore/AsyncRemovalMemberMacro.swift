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



package protocol AsyncRemovalMemberMacro: MemberMacro { }

extension AsyncRemovalMemberMacro
{
    /// Expands an attached macro to introduce member declarations within
    /// the given type declaration.
    /// - Parameters:
    ///   - node: The custom attribute describing the attached macro.
    ///   - declaration: The type declaration to which the macro attribute
    ///   is attached.
    ///   - protocols: The set of protocols to which the type conforms.
    ///   - context: The context in which to perform the macro expansion.
    /// - Returns: The set of member declarations.
    public static func expansion(
        of                  node        : AttributeSyntax,
        providingMembersOf  declaration : some DeclGroupSyntax,
        conformingTo        protocols   : [TypeSyntax],
        in                  context     : some MacroExpansionContext
    ) throws -> [DeclSyntax]
    {
        guard !declaration.is(ProtocolDeclSyntax.self)
        else
        {
            context.diagnose(Diagnostic(
                node:       node,
                message:    AsyncRemovalDiagnosticKind.protocolNotSupported
            ))
            
            return []
        }
        
        let rewriter    : AsyncRemovalRewriter  = .init()
        var members     : [DeclSyntax]          = []
        
        for member in declaration.memberBlock.members
        {
            guard
                let function = member.decl.as(FunctionDeclSyntax.self),
                !function.hasReasyncAttr,
                function.signature.effectSpecifiers?.asyncSpecifier != nil
            else
            {
                continue
            }
            
            let rewritten: FunctionDeclSyntax
                = rewriter.rewrite(function).cast(FunctionDeclSyntax.self)
            
            members.append(DeclSyntax(rewritten))
        }
        
        return members
    }
}
