//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import SwiftSyntax



/// A syntax rewriter that removes all `async` and `await` keywords from a
/// function declaration.
internal final class AsyncRemovalRewriter: SyntaxRewriter
{
    /// Visits the given function effect specifier node.
    /// - Parameter node: The node to visit.
    /// - Returns: A function effect specifier node.
    override func visit(
        _ node: FunctionEffectSpecifiersSyntax
    ) -> FunctionEffectSpecifiersSyntax
    {
        let visitedNode: FunctionEffectSpecifiersSyntax = super.visit(node)
        
        return transferLeadingTrivia(of: visitedNode)
    }
    
    
    
    /// Visits the given type effect specifier node.
    /// - Parameter node: The node to visit.
    /// - Returns: A type effect specifier node.
    override func visit(
        _ node: TypeEffectSpecifiersSyntax
    ) -> TypeEffectSpecifiersSyntax
    {
        let visitedNode: TypeEffectSpecifiersSyntax = super.visit(node)
        
        return transferLeadingTrivia(of: visitedNode)
    }
    
    
    
    /// Visits the given `await` expression node.
    /// - Parameter node: The node to visit.
    /// - Returns: An expression node.
    override func visit(
        _ node: AwaitExprSyntax
    ) -> ExprSyntax
    {
        let rewritten: ExprSyntax = super.visit(node)
        
        let awaitExpr = rewritten.as(AwaitExprSyntax.self) ?? node
        
        /// Preserve the leading trivia of the `await` in the inner expression,
        /// so that indentation is preserved.
        var inner: ExprSyntax = awaitExpr.expression
        
        inner.leadingTrivia = awaitExpr.awaitKeyword.leadingTrivia
        
        return inner
    }
    
    
    
    /// Visits the given variable declaration node.
    /// - Parameter node: The node to visit.
    /// - Returns: A declaration node.
    override func visit(
        _ node: VariableDeclSyntax
    ) -> DeclSyntax
    {
        var visitedNode: VariableDeclSyntax
            = super.visit(node).cast(VariableDeclSyntax.self)
        
        guard let asyncIndex: SyntaxChildrenIndex = visitedNode.modifiers
            .firstIndex(where: { $0.name.text == "async" })
        else
        {
            return DeclSyntax(visitedNode)
        }
        
        
        
        let asyncModifier: DeclModifierSyntax
            = visitedNode.modifiers[asyncIndex]
        
        visitedNode.modifiers.remove(at: asyncIndex)
        
        
        
        /// Transfer the leading trivia from `async` to `let`.
        if visitedNode.modifiers.isEmpty
        {
            visitedNode.bindingSpecifier.leadingTrivia
                = asyncModifier.name.leadingTrivia
        }
        else if var first: DeclModifierSyntax = visitedNode.modifiers.first
        {
            first.leadingTrivia = asyncModifier.name.leadingTrivia
            
            visitedNode.modifiers[visitedNode.modifiers.startIndex] = first
        }
        
        return DeclSyntax(visitedNode)
    }
    
    
    
    /// Visits the given `for` statement node.
    /// - Parameter node: The node to visit.
    /// - Returns: A statement node.
    override func visit(
        _ node: ForStmtSyntax
    ) -> StmtSyntax
    {
        var visitedNode: ForStmtSyntax
            = super.visit(node).cast(ForStmtSyntax.self)
        
        guard let awaitKeyword: TokenSyntax = visitedNode.awaitKeyword
        else
        {
            return StmtSyntax(visitedNode)
        }
        
        /// Transfer the leading trivia from `await` to `try`, or to the
        /// pattern if `try` is not present.
        if var tryKeyword: TokenSyntax = visitedNode.tryKeyword
        {
            tryKeyword.leadingTrivia    = awaitKeyword.leadingTrivia
            visitedNode.tryKeyword      = tryKeyword
        }
        else
        {
            visitedNode.pattern.leadingTrivia = awaitKeyword.leadingTrivia
        }
        
        visitedNode.awaitKeyword = nil
        
        return StmtSyntax(visitedNode)
    }
    
    
    
    // MARK: - Support
    
    /// Transfers the leading trivia of the given node to its `throws` clause
    /// syntax node, if it has one, and sets its `async` effect specifier to
    /// `nil`.
    ///
    /// This returns the visisted node without any further changes if it does
    /// not have an `async` effect specifier.
    ///
    /// - Parameter node: The node containing the trivia to transfer.
    /// - Returns: The visited node.
    private func transferLeadingTrivia<T>(
        of node: T
    ) -> T where T : EffectSpecifiersSyntax
    {
        var visitedNode: T = node
        
        guard let asyncSpecifier: TokenSyntax = visitedNode.asyncSpecifier
        else
        {
            return visitedNode
        }
        
        if var throwsClause: ThrowsClauseSyntax = visitedNode.throwsClause
        {
            /// `async throws`: Transfer the leading trivia of `async` to
            /// `throws`, so spacing relative to the prior token is preserved.
            throwsClause.throwsSpecifier.leadingTrivia
                = asyncSpecifier.leadingTrivia
            
            visitedNode.throwsClause = throwsClause
        }
        
        visitedNode.asyncSpecifier = nil
        
        return visitedNode
    }
}
