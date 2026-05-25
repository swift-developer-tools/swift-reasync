//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import SwiftSyntaxMacrosTestSupport
import XCTest



internal final class TriviaPreservationExpansionTests: XCTestCase
{
    func testDocCommentTransferralFromReasyncToFuncKeyword()
    {
        let functionSource: String =
        """
        /// Doubles the value.
        func double(_ value: Int) async -> Int { return value * 2 }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        /// Doubles the value.
        func double(_ value: Int) -> Int {
            return value * 2
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testDocCommentTransferralFromReasyncToFirstSurvivingModifier()
    {
        let functionSource: String =
        """
        func double(_ value: Int) async -> Int { return value * 2 }
        """
        
        let originalSource: String =
        """
        /// Doubles the value.
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        /// Doubles the value.
        \(functionSource)
        
        /// Doubles the value.
        func double(_ value: Int) -> Int {
            return value * 2
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testDocCommentTransferralFromReasyncToFirstSurvivingAttribute()
    {
        let functionSource: String =
        """
        func double(_ value: Int) async -> Int { return value * 2 }
        """
        
        let originalSource: String =
        """
        /// Doubles the value.
        @Reasync
        @discardableResult
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        /// Doubles the value.
        @discardableResult
        \(functionSource)
        
        /// Doubles the value.
        @discardableResult
        func double(_ value: Int) -> Int {
            return value * 2
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testNonisolatedNonsendingRemovalChainsTriviaToFuncKeyword()
    {
        let functionSource: String =
        """
        // A leading comment.
        nonisolated(nonsending)
        func run() async { }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        // A leading comment.
        func run() {
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testClosureParamPartialRemovalChainsTriviaToPreservedAttribute()
    {
        let functionSource: String =
        """
        func run(
            _ body: @concurrent /* mid */ @MainActor () async -> Void
        ) async
        {
            await body()
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run(
            _ body: /* mid */ @MainActor () -> Void
        )
        {
            body()
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testClosureParamFullRemovalUnwrapsAttributedTypeWithoutWhitespace()
    {
        let functionSource: String =
        """
        func run(
            _ body: nonisolated(nonsending) @Sendable @isolated(any) @concurrent () async -> Void
        ) async
        {
            await body()
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run(
            _ body: () -> Void
        )
        {
            body()
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testClosureParamFullRemovalPreservesCommentInClusterOnBaseType()
    {
        let functionSource: String =
        """
        func run(
            _ body: nonisolated(nonsending) /* mid */ @Sendable () async -> Void
        ) async
        {
            await body()
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run(
            _ body: /* mid */ () -> Void
        )
        {
            body()
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAsyncRemovalFromClosureSignatureWithReturnClause()
    {
        let functionSource: String =
        """
        func run() async
        {
            let result =
            {
                () async -> Int in
        
                return 0
            }()
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run()
        {
            let result =
            {
                () -> Int in
        
                return 0
            }()
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAsyncRemovalFromClosureSignatureWithoutReturnClause()
    {
        let functionSource: String =
        """
        func run() async
        {
            let closure =
            {
                () async in
        
                someFunction()
            }
        
            await closure()
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run()
        {
            let closure =
            {
                () in
        
                someFunction()
            }
        
            closure()
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAsyncRemovalFromAccessorPlacesTriviaOnBrace()
    {
        let functionSource: String =
        """
        func run() async -> Int
        {
            var x: Int
            {
                get async
                {
                    return 0
                }
            }
        
            return await x
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run() -> Int
        {
            var x: Int
            {
                get
                {
                    return 0
                }
            }
        
            return x
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAsyncRemovalFromAsyncThrowsFunctionPlacesTriviaOnThrows()
    {
        let functionSource: String =
        """
        func run() async throws { }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run() throws {
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAsyncLetRemovalChainsTriviaToLetKeyword()
    {
        let functionSource: String =
        """
        func run() async -> Int
        {
            // A leading comment.
            async let x: Int = 0
        
            return await x
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run() -> Int
        {
            // A leading comment.
            let x: Int = 0
        
            return x
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testForAwaitRemovalChainsTriviaToPattern()
    {
        let functionSource: String =
        """
        func run(_ sequence: SomeAsyncSequence) async
        {
            // A leading comment.
            for await element in sequence
            {
                _ = element
            }
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run(_ sequence: SomeAsyncSequence)
        {
            // A leading comment.
            for element in sequence
            {
                _ = element
            }
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testForAwaitRemovalChainsTriviaBetweenForAndAwait()
    {
        let functionSource: String =
        """
        func run(_ sequence: SomeAsyncSequence) async
        {
            for /* mid */ await element in sequence
            {
                _ = element
            }
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run(_ sequence: SomeAsyncSequence)
        {
            for /* mid */ element in sequence
            {
                _ = element
            }
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testForTryAwaitRemovalChainsTriviaToTryKeyword()
    {
        let functionSource: String =
        """
        func run(_ sequence: SomeAsyncSequence) async throws
        {
            // A leading comment.
            for try await element in sequence
            {
                _ = element
            }
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run(_ sequence: SomeAsyncSequence) throws
        {
            // A leading comment.
            for try element in sequence
            {
                _ = element
            }
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testForTryAwaitRemovalChainsTriviaBetweenTryAndAwait()
    {
        let functionSource: String =
        """
        func run(_ sequence: SomeAsyncSequence) async throws
        {
            for try /* mid */ await element in sequence
            {
                _ = element
            }
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run(_ sequence: SomeAsyncSequence) throws
        {
            for try /* mid */ element in sequence
            {
                _ = element
            }
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAwaitRemovalChainsTriviaToInnerExpression()
    {
        let functionSource: String =
        """
        func run() async -> Int
        {
            let x = /* before */ await someFunction()
        
            return x
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run() -> Int
        {
            let x = /* before */ someFunction()
        
            return x
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testForTryAwaitRemovalChainsTriviaBetweenTryAndAwaitAcrossNewlines()
    {
        let functionSource: String =
        """
        func run(_ sequence: SomeAsyncSequence) async throws
        {
            for try
                /* mid */
                await element in sequence
            {
                _ = element
            }
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run(_ sequence: SomeAsyncSequence) throws
        {
            for try
                /* mid */
                element in sequence
            {
                _ = element
            }
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAsyncRemovalFromFunctionDeclChainsTriviaToRightParenAcrossNewlines()
    {
        let functionSource: String =
        """
        func run()
            /* mid */
            async -> Int
        {
            return 0
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run()
            /* mid */
            -> Int
        {
            return 0
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAsyncRemovalFromFunctionTypeChainsTriviaToRightParenAcrossNewlines()
    {
        let functionSource: String =
        """
        func run(
            _ body: (Int)
                /* mid */
                async -> Int
        ) async -> Int
        {
            return await body(0)
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run(
            _ body: (Int)
                /* mid */
                -> Int
        ) -> Int
        {
            return body(0)
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testSendingParamPreservesTriviaBeforeSpecifier()
    {
        let functionSource: String =
        """
        func run(
            _ box: /* mid */ sending Box
        ) async
        {
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run(
            _ box: /* mid */ sending Box
        )
        {
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testSendingReturnPreservesTriviaBeforeSpecifier()
    {
        let functionSource: String =
        """
        func run() async -> /* mid */ sending Box
        {
            return Box()
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run() -> /* mid */ sending Box
        {
            return Box()
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAwaitRemovalPreservesCommentBetweenAwaitAndExpression()
    {
        let functionSource: String =
        """
        func run() async -> Int
        {
            let x = await /* mid */ someFunction()
        
            return x
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run() -> Int
        {
            let x = /* mid */ someFunction()

            return x
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAwaitRemovalInSubExpression()
    {
        let functionSource: String =
        """
        func run() async -> Int
        {
            return 1 + /* before */ await /* mid */ someFunction() /* after */
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run() -> Int
        {
            return 1 + /* before */ /* mid */ someFunction() /* after */
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testForAwaitRemovalPreservesCommentBetweenAwaitAndPattern()
    {
        let functionSource: String =
        """
        func run(
            _ sequence: SomeAsyncSequence
        ) async
        {
            for await /* mid */ element in sequence
            {
                _ = element
            }
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run(
            _ sequence: SomeAsyncSequence
        )
        {
            for /* mid */ element in sequence
            {
                _ = element
            }
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAsyncLetRemovalPreservesCommentBetweenAsyncAndLet()
    {
        let functionSource: String =
        """
        func run() async -> Int
        {
            async /* mid */ let x: Int = 0
        
            return await x
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run() -> Int
        {
            /* mid */ let x: Int = 0
        
            return x
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAsyncRemovalFromFuncSignaturePreservesCommentBetweenAsyncAndThrows()
    {
        let functionSource: String =
        """
        func run() async /* mid */ throws
        {
            throw SomeError()
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run() /* mid */ throws
        {
            throw SomeError()
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAsyncRemovalFromFuncSignaturePreservesCommentBetweenAsyncAndArrow()
    {
        let functionSource: String =
        """
        func run() async /* mid */ -> Int
        {
            return 0
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let expandedSource: String =
        """
        \(functionSource)
        
        func run() /* mid */ -> Int
        {
            return 0
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
}
