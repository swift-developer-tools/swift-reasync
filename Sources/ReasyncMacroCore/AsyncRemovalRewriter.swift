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



/// A syntax rewriter that transforms the syntax tree of an `async` function
/// declaration into the syntax tree of an equivalent synchronous declaration.
///
/// The rewriter removes the `async` and `await` keywords throughout the
/// declaration, along with constructs that depend on them: `async let`
/// bindings become `let` bindings, and `for await` loops become `for` loops.
///
/// The rewriter also removes the `@isolated(any)`, `@concurrent`, and
/// `nonisolated(nonsending)` concurrency annotations from positions where they
/// are invalid on a synchronous function or function type, and removes
/// `@Sendable` from closure types in the function's parameter clause.
///
/// Wherever a removal would leave behind redundant or orphaned trivia, the
/// rewriter transfers the trivia to a nearby meaningful token so that the
/// rewritten declaration retains the formatting of the source.
///
/// The rewriter visits the root function declaration and all of its
/// descendants, including nested function declarations, closure expressions,
/// and local computed properties. Nested function declarations annotated with
/// `@Reasync` are diagnosed with a warning and a fix-it to remove the
/// redundant attribute, since the enclosing macro already transforms them.
internal final class AsyncRemovalRewriter<Context>: SyntaxRewriter
    where Context: MacroExpansionContext
{
    /// The identifier of the root function declaration.
    ///
    /// The rewriter is initialized with the root function and visits its
    /// descendants. This identifier is used to distinguish the root from any
    /// nested function declarations encountered during traversal.
    private let rootFunctionID          : SyntaxIdentifier
    
    /// The macro expansion context.
    ///
    /// This is used for emitting diagnostics from within the rewriter.
    private let context                 : Context
    
    /// The depth of nesting inside a function declaration's parameter clause.
    ///
    /// `@Sendable` is removed from closure types only when this is non-zero,
    /// since the macro's transformation eliminates parallel execution arising
    /// from the function body's use of closure parameters, but does not alter
    /// the meaning of `@Sendable` on closure types appearing in the body
    /// itself.
    private var parameterClauseDepth    : Int               = 0
    
    
    
    /// Initializes an ``AsyncRemovalRewriter`` instance from the given values.
    /// - Parameters:
    ///   - rootFunction: The function declaration to which `@Reasync` is
    ///   attached. The rewriter will visit this declaration and its
    ///   descendants.
    ///   - context: The macro expansion context.
    internal init(
        rootFunction    : FunctionDeclSyntax,
        context         : Context
    )
    {
        self.rootFunctionID     = rootFunction.id
        self.context            = context
        
        super.init()
    }
    
    
    
    // MARK: - Visit
    
    /// Visits the given accessor declaration node.
    ///
    /// This removes the `async` effect specifier from the accessors's effect
    /// specifiers, transferring its leading trivia to the next surviving
    /// sibling. If removing `async` leaves the effect specifiers node empty,
    /// the entire node is removed.
    ///
    /// - Parameter node: The node to visit.
    /// - Returns: An declaration node.
    override func visit(
        _ node: AccessorDeclSyntax
    ) -> DeclSyntax
    {
        var visitedNode = super.visit(node).cast(AccessorDeclSyntax.self)
        
        guard let effectSpecifiers: AccessorEffectSpecifiersSyntax
                = visitedNode.effectSpecifiers
        else
        {
            return DeclSyntax(visitedNode)
        }
        
        let removal: AsyncRemovalResult<AccessorEffectSpecifiersSyntax>
            = Self.removingAsyncSpecifier(from: effectSpecifiers)
        
        if
            removal.node.asyncSpecifier == nil,
            removal.node.throwsClause == nil
        {
            visitedNode.effectSpecifiers = nil
        }
        else
        {
            visitedNode.effectSpecifiers = removal.node
        }
        
        if !removal.leftoverTrivia.isEmpty
        {
            Self.placeLeftoverTriviaInAccessorDecl(
                removal.leftoverTrivia,
                of: &visitedNode
            )
        }
        
        return DeclSyntax(visitedNode)
    }
    
    
    
    /// Visits the given arrow expression node.
    ///
    /// This removes the `async` effect specifier from the expression's effect
    /// specifiers, transferring its leading trivia to the arrow token. If
    /// removing `async` leaves the effect specifiers node empty, the entire
    /// node is removed.
    ///
    /// - Parameter node: The node to visit.
    /// - Returns: An expression node.
    override func visit(
        _ node: ArrowExprSyntax
    ) -> ExprSyntax
    {
        var visitedNode = super.visit(node).cast(ArrowExprSyntax.self)
        
        guard let effectSpecifiers: TypeEffectSpecifiersSyntax
                = visitedNode.effectSpecifiers
        else
        {
            return ExprSyntax(visitedNode)
        }
        
        let removal: AsyncRemovalResult<TypeEffectSpecifiersSyntax>
            = Self.removingAsyncSpecifier(from: effectSpecifiers)
        
        if
            removal.node.asyncSpecifier == nil,
            removal.node.throwsClause == nil
        {
            visitedNode.effectSpecifiers = nil
        }
        else
        {
            visitedNode.effectSpecifiers = removal.node
        }
        
        if !removal.leftoverTrivia.isEmpty
        {
            visitedNode.arrow.leadingTrivia.prepend(removal.leftoverTrivia)
        }
        
        return ExprSyntax(visitedNode)
    }
    
    
    
    /// Visits the given attributed type node.
    ///
    /// On a function-typed node, this unconditionally removes `@concurrent`
    /// from the attribute list and `nonisolated(nonsending)` from the
    /// specifier and late-specifier lists, since neither of these are valid on
    /// synchronous function types. `@Sendable` and `@isolated(any)` are
    /// removed from the attribute list only when the node appears inside a
    /// function declaration's parameter clause, since outside of that position
    /// the macro has not transformed the surrounding constructs that motivated
    /// the annotation. The leading trivia of each removed item is transferred
    /// to the next surviving element in source order, or to the base type if
    /// no elements survive.
    ///
    /// If the resulting `AttributedTypeSyntax` wrapper contains no specifiers,
    /// attributes, or late specifiers, then it serves no syntactic purpose and
    /// this will return the base type directly to avoid emitting a
    /// structurally-vacuous wrapper.
    ///
    /// - Parameter node: The node to visit.
    /// - Returns: A type node.
    override func visit(
        _ node: AttributedTypeSyntax
    ) -> TypeSyntax
    {
        let visitedNode = super.visit(node).cast(AttributedTypeSyntax.self)
        
        let isFunctionType: Bool = visitedNode
            .baseType
            .is(FunctionTypeSyntax.self)
        
        var pendingTrivia: Trivia = []
        
        let shouldRemoveAttribute: (AttributeListSyntax.Element) -> Bool =
        {
            guard
                isFunctionType,
                case let .attribute(attr) = $0
            else
            {
                return false
            }
            
            if attr.isConcurrent
            {
                return true
            }
            
            if
                attr.isIsolatedAny
                || attr.isSendable
            {
                return self.parameterClauseDepth > 0
            }
            
            return false
        }
        
        let newSpecifiers: TypeSpecifierListSyntax = Self.filtering(
            visitedNode.specifiers,
            removingWhen:   { isFunctionType && $0.isNonisolatedNonsending },
            pendingTrivia:  &pendingTrivia
        )
        
        let newAttributes: AttributeListSyntax = Self.filtering(
            visitedNode.attributes,
            removingWhen:   shouldRemoveAttribute,
            pendingTrivia:  &pendingTrivia
        )
        
        let newLateSpecifiers: TypeSpecifierListSyntax = Self.filtering(
            visitedNode.lateSpecifiers,
            removingWhen:   { isFunctionType && $0.isNonisolatedNonsending },
            pendingTrivia:  &pendingTrivia
        )
        
        
        
        var result: AttributedTypeSyntax = visitedNode
        
        result.specifiers       = newSpecifiers
        result.attributes       = newAttributes
        result.lateSpecifiers   = newLateSpecifiers
        
        if !pendingTrivia.isEmpty
        {
            result.baseType.leadingTrivia.prepend(pendingTrivia)
        }
        
        if
            result.specifiers.isEmpty,
            result.attributes.isEmpty,
            result.lateSpecifiers.isEmpty
        {
            return result.baseType
        }
        
        return TypeSyntax(result)
    }
    
    
    
    /// Visits the given `await` expression node.
    ///
    /// This removes the `await` keyword from the expression and transfers its
    /// leading trivia to the inner expression.
    ///
    /// - Parameter node: The node to visit.
    /// - Returns: An expression node.
    override func visit(
        _ node: AwaitExprSyntax
    ) -> ExprSyntax
    {
        let rewritten: ExprSyntax = super.visit(node)
        
        let awaitExpr = rewritten.as(AwaitExprSyntax.self) ?? node
        
        var inner: ExprSyntax = awaitExpr.expression
        
        inner.leadingTrivia.prepend(awaitExpr.awaitKeyword.triviaForRemoval)
        
        return inner
    }
    
    
    
    /// Visits the given closure expression node.
    ///
    /// This removes the `async` effect specifier from the closure's signature,
    /// transferring its leading trivia to the next surviving sibling. If
    /// removing `async` leaves the effect specifiers node empty, the entire
    /// node is removed.
    ///
    /// - Parameter node: The node to visit.
    /// - Returns: An expression node.
    override func visit(
        _ node: ClosureExprSyntax
    ) -> ExprSyntax
    {
        var visitedNode = super.visit(node).cast(ClosureExprSyntax.self)
        
        guard
            var signature: ClosureSignatureSyntax = visitedNode.signature,
            let effectSpecifiers: TypeEffectSpecifiersSyntax
                = signature.effectSpecifiers
        else
        {
            return ExprSyntax(visitedNode)
        }
        
        let removal: AsyncRemovalResult<TypeEffectSpecifiersSyntax>
            = Self.removingAsyncSpecifier(from: effectSpecifiers)
        
        if
            removal.node.asyncSpecifier == nil,
            removal.node.throwsClause == nil
        {
            signature.effectSpecifiers = nil
        }
        else
        {
            signature.effectSpecifiers = removal.node
        }
        
        if !removal.leftoverTrivia.isEmpty
        {
            Self.placeLeftoverTriviaInClosureSignature(
                removal.leftoverTrivia,
                of: &signature
            )
        }
        
        visitedNode.signature = signature
        
        return ExprSyntax(visitedNode)
    }
    
    
    
    /// Visits the given `for` statement node.
    ///
    /// This removes the `await` keyword from a `for await` loop and transfers
    /// its leading trivia to the `try` keyword's trailing trivia if present,
    /// or to the loop pattern's leading trivia otherwise.
    ///
    /// - Parameter node: The node to visit.
    /// - Returns: A statement node.
    override func visit(
        _ node: ForStmtSyntax
    ) -> StmtSyntax
    {
        var visitedNode = super.visit(node).cast(ForStmtSyntax.self)
        
        guard let awaitKeyword: TokenSyntax = visitedNode.awaitKeyword
        else
        {
            return StmtSyntax(visitedNode)
        }
        
        if var tryKeyword: TokenSyntax = visitedNode.tryKeyword
        {
            tryKeyword.trailingTrivia += awaitKeyword.triviaForRemoval
            
            visitedNode.tryKeyword = tryKeyword
        }
        else
        {
            visitedNode.pattern.leadingTrivia
                .prepend(awaitKeyword.triviaForRemoval)
        }
        
        visitedNode.awaitKeyword = nil
        
        return StmtSyntax(visitedNode)
    }
    
    
    
    /// Visits the given function declaration node.
    ///
    /// This removes `@Reasync` and `@concurrent` attributes from the
    /// declaration's attribute list, as well as any `nonisolated(nonsending)`
    /// modifier. The leading trivia of each removed item is transferred to
    /// the next surviving element in source order, or to the `func` keyword
    /// if no attributes or modifiers survive.
    ///
    /// If this function declaration is nested within the root function
    /// declaration (in other words, it is not itself the root) and carries
    /// an `@Reasync` attribute, a warning is emitted indicating that the
    /// nested attribute is redundant, with a fix-it to remove it.
    ///
    /// - Parameter node: The node to visit.
    /// - Returns: A declaration node.
    override func visit(
        _ node: FunctionDeclSyntax
    ) -> DeclSyntax
    {
        let isNested: Bool = node.id != rootFunctionID
        
        if
            isNested,
            let reasyncAttributeIndex: AttributeListSyntax.Index
                = node.reasyncAttributeIndex,
            case let .attribute(reasyncAttribute)
                = node.attributes[reasyncAttributeIndex]
        {
            diagnoseNestedReasync(
                attribute:          reasyncAttribute,
                attributeIndex:     reasyncAttributeIndex,
                function:           node
            )
        }
        
        
        
        let visitedNode = super.visit(node).cast(FunctionDeclSyntax.self)
        
        var pendingTrivia: Trivia = []
        
        let newAttributes: AttributeListSyntax = Self.filtering(
            visitedNode.attributes,
            removingWhen:   { $0.requiresRemovalOnFunctionDeclaration },
            pendingTrivia:  &pendingTrivia
        )
        
        let newModifiers: DeclModifierListSyntax = Self.filtering(
            visitedNode.modifiers,
            removingWhen:   { $0.isNonisolatedNonsending },
            pendingTrivia:  &pendingTrivia
        )
        
        
        
        var result: FunctionDeclSyntax = visitedNode
        
        result.attributes   = newAttributes
        result.modifiers    = newModifiers
        
        if !pendingTrivia.isEmpty
        {
            result.funcKeyword.leadingTrivia.prepend(pendingTrivia)
        }
        
        
        
        if let effectSpecifiers: FunctionEffectSpecifiersSyntax
            = result.signature.effectSpecifiers
        {
            let removal: AsyncRemovalResult<FunctionEffectSpecifiersSyntax>
                = Self.removingAsyncSpecifier(from: effectSpecifiers)
            
            if
                removal.node.asyncSpecifier == nil,
                removal.node.throwsClause == nil
            {
                result.signature.effectSpecifiers = nil
            }
            else
            {
                result.signature.effectSpecifiers = removal.node
            }
            
            if !removal.leftoverTrivia.isEmpty
            {
                Self.placeLeftoverTriviaInFunctionDecl(
                    removal.leftoverTrivia,
                    of: &result
                )
            }
        }
        
        
        return DeclSyntax(result)
    }
    
    
    
    /// Visits the given function parameter clause node.
    ///
    /// This incremenets the ``parameterClauseDepth`` for the duration of the
    /// visit, allowing other visitors to identify whether a node appears
    /// inside a function declaration's parameter clause.
    ///
    /// - Parameter node: The node to visit.
    /// - Returns: A function parameter clause node.
    override func visit(
        _ node: FunctionParameterClauseSyntax
    ) -> FunctionParameterClauseSyntax
    {
        parameterClauseDepth += 1
        
        defer
        {
            parameterClauseDepth -= 1
        }
        
        return super.visit(node)
    }
    
    
    
    /// Visits the given function type node.
    ///
    /// This removes any `async` effect specifier from the type's signature,
    /// transferring its leading trivia to the right parenthesis's trailing
    /// trivia. If removing `async` leaves the effect specifiers node empty,
    /// the entire node is removed.
    ///
    /// - Parameter node: The node to visit.
    /// - Returns: A type node.
    override func visit(
        _ node: FunctionTypeSyntax
    ) -> TypeSyntax
    {
        var visitedNode = super.visit(node).cast(FunctionTypeSyntax.self)
        
        guard let effectSpecifiers: TypeEffectSpecifiersSyntax
                = visitedNode.effectSpecifiers
        else
        {
            return TypeSyntax(visitedNode)
        }
        
        let removal: AsyncRemovalResult<TypeEffectSpecifiersSyntax>
            = Self.removingAsyncSpecifier(from: effectSpecifiers)
        
        if
            removal.node.asyncSpecifier == nil,
            removal.node.throwsClause == nil
        {
            visitedNode.effectSpecifiers = nil
        }
        else
        {
            visitedNode.effectSpecifiers = removal.node
        }
        
        if !removal.leftoverTrivia.isEmpty
        {
            visitedNode.rightParen.trailingTrivia += removal.leftoverTrivia
        }
        
        return TypeSyntax(visitedNode)
    }
    
    
    
    /// Visits the given variable declaration node.
    ///
    /// This removes any `async` modifier and transfers its leading trivia
    /// to the next surviving modifier, or to the binding specifier if no
    /// modifiers survive.
    ///
    /// - Parameter node: The node to visit.
    /// - Returns: A declaration node.
    override func visit(
        _ node: VariableDeclSyntax
    ) -> DeclSyntax
    {
        var visitedNode = super.visit(node).cast(VariableDeclSyntax.self)
        
        guard let asyncIndex: SyntaxChildrenIndex = visitedNode.modifiers
            .firstIndex(where: { $0.name.text == "async" })
        else
        {
            return DeclSyntax(visitedNode)
        }
        
        
        
        let asyncModifier: DeclModifierSyntax
            = visitedNode.modifiers[asyncIndex]
        
        visitedNode.modifiers.remove(at: asyncIndex)
        
        
        
        if visitedNode.modifiers.isEmpty
        {
            visitedNode.bindingSpecifier.leadingTrivia
                .prepend(asyncModifier.name.triviaForRemoval)
        }
        else if var first: DeclModifierSyntax = visitedNode.modifiers.first
        {
            first.leadingTrivia.prepend(asyncModifier.name.triviaForRemoval)
            
            visitedNode.modifiers[visitedNode.modifiers.startIndex] = first
        }
        
        return DeclSyntax(visitedNode)
    }
    
    
    
    // MARK: - Remove async
    
    /// The result of removing the `async` specifier from a node containing
    /// effect specifiers.
    private struct AsyncRemovalResult<T> where T: EffectSpecifiersSyntax
    {
        /// The node with its `async` specifier removed.
        let node            : T
        
        /// Leading trivia from the removed `async` specifier that could not
        /// be absorbed into the node.
        ///
        /// The parent visitor is responsible for placing this on an
        /// appropriate sibling.
        let leftoverTrivia  : Trivia
    }
    
    
    
    /// Removes the `async` effect specifier from the given node.
    ///
    /// If the node has a `throws` clause, the leading trivia of the removed
    /// `async` specifier is transferred to the `throws` specifier, and the
    /// returned ``AsyncRemovalResult/leftoverTrivia`` is empty.
    ///
    /// If the node does not have a `throws` clause, the leading trivia of the
    /// removed `async` specifier cannot be absorbed locally, and is returned
    /// in ``AsyncRemovalResult/leftoverTrivia`` for the parent visitor to
    /// place on an appropriate sibling.
    ///
    /// If the node does not have an `async` specifier, the node is returned
    /// unchanged, and the returned ``AsyncRemovalResult/leftoverTrivia`` is
    /// empty.
    ///
    /// - Parameter node: The node from which to remove the `async` specifier.
    /// - Returns: The result of the removal.
    private static func removingAsyncSpecifier<T>(
        from node: T
    ) -> AsyncRemovalResult<T> where T: EffectSpecifiersSyntax
    {
        var result: T = node
        
        guard let asyncSpecifier: TokenSyntax = result.asyncSpecifier
        else
        {
            return AsyncRemovalResult(
                node:               result,
                leftoverTrivia:     []
            )
        }
        
        result.asyncSpecifier = nil
        
        if var throwsClause: ThrowsClauseSyntax = result.throwsClause
        {
            throwsClause.throwsSpecifier.leadingTrivia
                .prepend(asyncSpecifier.triviaForRemoval)
            
            result.throwsClause = throwsClause
            
            return AsyncRemovalResult(
                node:               result,
                leftoverTrivia:     []
            )
        }
        
        return AsyncRemovalResult(
            node:               result,
            leftoverTrivia:     asyncSpecifier.triviaForRemoval
        )
    }
    
    
    
    // MARK: - Trivia
    
    /// Places the given leftover trivia from a removed `async` specifier in
    /// the given accessor declaration.
    ///
    /// The trivia is placed on the opening brace of the accessor's body.
    /// `@Reasync` only attaches to function declarations, so accessors are
    /// reached only through the body of an enclosing function, where they
    /// belong to local computed properties and always have bodies.
    ///
    /// - Parameters:
    ///   - trivia: The leftover trivia to place.
    ///   - accessor: The accessor declaration to modify.
    private static func placeLeftoverTriviaInAccessorDecl(
        _   trivia      : Trivia,
        of  accessor    : inout AccessorDeclSyntax
    )
    {
        guard var body: CodeBlockSyntax = accessor.body
        else
        {
            return
        }
        
        body.leftBrace.leadingTrivia.prepend(trivia)
        
        accessor.body = body
    }
    
    
    
    /// Places the given leftover trivia from a removed `async` specifier in
    /// the given closure signature.
    ///
    /// The trivia is placed on the next surviving sibling of the effect
    /// specifiers in the closure signature, in the following order of
    /// preference:
    ///
    /// 1. The arrow of the return clause.
    /// 2. The `in` keyword of the closure signature.
    ///
    /// - Parameters:
    ///   - trivia: The leftover trivia to place.
    ///   - signature: The closure signature to modify.
    private static func placeLeftoverTriviaInClosureSignature(
        _   trivia      : Trivia,
        of  signature   : inout ClosureSignatureSyntax
    )
    {
        if var returnClause: ReturnClauseSyntax = signature.returnClause
        {
            returnClause.arrow.leadingTrivia.prepend(trivia)
            
            signature.returnClause = returnClause
            
            return
        }
        
        signature.inKeyword.leadingTrivia.prepend(trivia)
    }
    
    
    
    /// Places the given leftover trivia from a removed `async` specifier in
    /// the given function declaration.
    ///
    /// The trivia is placed on the trailing trivia of the parameter clause's
    /// right parenthesis.
    ///
    /// - Parameters:
    ///   - trivia: The leftover trivia to place.
    ///   - decl: The function declaration to modify.
    private static func placeLeftoverTriviaInFunctionDecl(
        _   trivia  : Trivia,
        of  decl    : inout FunctionDeclSyntax
    )
    {
        decl.signature.parameterClause.rightParen.trailingTrivia += trivia
    }
    
    
    
    // MARK: - Filter
    
    /// Returns a copy of the given syntax collection with every element
    /// matched by `removingWhen` removed, threading trivia from removed
    /// elements onto the next surviving element.
    ///
    /// When an element is removed, its leading and trailing trivia are
    /// accumulated into `pendingTrivia` with their outer whitespace runs
    /// removed. The trailing run of the leading trivia is the visual
    /// separation that positioned the removed element (newline plus
    /// indentation, or trailing spaces before it); the leading run of the
    /// trailing trivia is the visual separation that followed it. With the
    /// element gone, both runs are redundant, and removing them prevents the
    /// merge from introducing spurious blank lines or stranded indentation on
    /// a surviving sibling. Interior trivia, including whitespace between
    /// meaningful pieces such as source comments, is preserved so that
    /// comments embedded around removed elements survive on the next surviving
    /// element.
    ///
    /// When a surviving element is encountered, `pendingTrivia` is prepended
    /// to its leading trivia, then reset to empty. If no element survives
    /// after iteration completes, `pendingTrivia` is left non-empty on return
    /// for the caller to apply to a fallback target such as a sibling token.
    ///
    /// `pendingTrivia` is read on entry and prepended to the first surviving
    /// element's leading trivia before any removed-element trivia is added,
    /// allowing this method to be chained with other filtering operations over
    /// related collections (for example, filtering a type's specifiers, then
    /// its attributes, then its late specifiers) without losing trivia at the
    /// boundaries between them.
    ///
    /// - Parameters:
    ///   - collection: The syntax collection to filter.
    ///   - removingWhen: A predicate that returns `true` for elements that
    ///   should be removed.
    ///   - pendingTrivia: Trivia from previously-removed elements to prepend
    ///   to the next surviving element. On return, this contains any trivia
    ///   from removed elements that was not absorbed by a surviving element
    ///   in the given collection.
    /// - Returns: A new collection of the same type, containing only the
    /// surviving elements, with trivia adjusted as needed.
    private static func filtering<C>(
        _ collection    : C,
        removingWhen    : (C.Element) -> Bool,
        pendingTrivia   : inout Trivia
    ) -> C where C: SyntaxCollection
    {
        var result = C()
        
        for element in collection
        {
            if removingWhen(element)
            {
                pendingTrivia += element.leadingTrivia.triviaBeforeTrailingWhitespace
                pendingTrivia += element.trailingTrivia.triviaAfterLeadingWhitespace
            }
            else
            {
                var survivingElement: C.Element = element
                
                survivingElement.leadingTrivia.prepend(pendingTrivia)
                
                pendingTrivia = []
                
                result.append(survivingElement)
            }
        }
        
        return result
    }
    
    
    
    // MARK: - Diagnose
    
    /// Emits a warning diagnostic that the given `@Reasync` attribute on the
    /// given nested function declaration has no effect, along with a fix-it
    /// to remove the attribute.
    ///
    /// - Parameters:
    ///   - attribute: The `@Reasync` attribute on the nested function.
    ///   - attributeIndex: The index of the `@Reasync` attribute in the
    ///   nested function's attribute list, used to compute the fix-it's
    ///   replacement node.
    ///   - function: The nested function declaration carrying the `@Reasync`
    ///   attribute. This is the unmodified function as seen during traversal,
    ///   used to compute the fix-it's replacement node.
    private func diagnoseNestedReasync(
        attribute       : AttributeSyntax,
        attributeIndex  : AttributeListSyntax.Index,
        function        : FunctionDeclSyntax
    )
    {
        let fixedFunction: FunctionDeclSyntax = function
            .removingAttribute(at: attributeIndex)
        
        let fixIt = FixIt(
            message: AsyncRemovalFixItKind.removeNestedReasync,
            changes:
            [
                .replace(
                    oldNode:    Syntax(function),
                    newNode:    Syntax(fixedFunction)
                )
            ]
        )
        
        context.diagnose(Diagnostic(
            node:       attribute,
            message:    AsyncRemovalDiagnosticKind.nestedReasync,
            fixIts:     [fixIt]
        ))
    }
}
