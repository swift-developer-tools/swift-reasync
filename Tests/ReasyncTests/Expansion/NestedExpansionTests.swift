//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

@testable import ReasyncMacroCore
import SwiftSyntaxMacrosTestSupport
import XCTest



internal final class NestedExpansionTests: XCTestCase
{
    func testNestedAsyncFunctionTransformation()
    {
        let functionSource: String =
        """
        func outer() async -> Int
        {
            func inner() async -> Int
            {
                return 0
            }
        
            return await inner()
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
        
        func outer() -> Int
        {
            func inner() -> Int
            {
                return 0
            }
        
            return inner()
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testNestedFunctionConcurrencyAnnotationsRemoval()
    {
        let functionSource: String =
        """
        func outer() async
        {
            @concurrent
            nonisolated(nonsending)
            func inner(
                _ body: @Sendable @isolated(any) () async -> Void
            ) async
            {
                await body()
            }
        
            await inner(someFunction)
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
        
        func outer()
        {
            func inner(
                _ body: () -> Void
            )
            {
                body()
            }
        
            inner(someFunction)
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testDeeplyNestedClosureTypeAnnotationRemoval()
    {
        let functionSource: String =
        """
        func run(
            _ body: @isolated(any) (@Sendable () async -> Int) async -> Int
        ) async -> Int
        {
            return await body(someFunction)
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
            _ body: (() -> Int) -> Int
        ) -> Int
        {
            return body(someFunction)
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testDeeplyNestedAsyncFunctionTransformation()
    {
        let functionSource: String =
        """
        func outer() async -> Int
        {
            func middle() async -> Int
            {
                func inner() async -> Int
                {
                    return 0
                }
        
                return await inner()
            }
        
            return await middle()
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
        
        func outer() -> Int
        {
            func middle() -> Int
            {
                func inner() -> Int
                {
                    return 0
                }
        
                return inner()
            }
        
            return middle()
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testNestedReasyncWarningWithFixItEmission()
    {
        let originalSource: String =
        """
        @Reasync
        func outer() async -> Int
        {
            @Reasync
            func inner() async -> Int
            {
                return 0
            }
        
            return await inner()
        }
        """
        
        let expandedSource: String =
        """
        func outer() async -> Int
        {
            func inner() async -> Int
            {
                return 0
            }

            func inner() -> Int
            {
                return 0
            }

            return await inner()
        }

        func outer() -> Int
        {
            func inner() -> Int
            {
                return 0
            }

            return inner()
        }
        """
        
        let message: String = AsyncRemovalDiagnosticKind
            .nestedReasync
            .message
        
        let fixIt = FixItSpec(
            message: AsyncRemovalFixItKind.removeNestedReasync.message
        )
        
        let diagnostic = DiagnosticSpec(
            message:    message,
            line:       4,
            column:     5,
            severity:   .warning,
            fixIts:     [fixIt]
        )
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            diagnostics:        [diagnostic],
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testDeeplyNestedReasyncWarningWithFixItEmission()
    {
        let originalSource: String =
        """
        @Reasync
        func outer() async -> Int
        {
            func middle() async -> Int
            {
                @Reasync
                func inner() async -> Int
                {
                    return 0
                }
        
                return await inner()
            }
        
            return await middle()
        }
        """
        
        let expandedSource: String =
        """
        func outer() async -> Int
        {
            func middle() async -> Int
            {
                func inner() async -> Int
                {
                    return 0
                }

                func inner() -> Int
                {
                    return 0
                }

                return await inner()
            }

            return await middle()
        }

        func outer() -> Int
        {
            func middle() -> Int
            {
                func inner() -> Int
                {
                    return 0
                }

                return inner()
            }

            return middle()
        }
        """
        
        let message: String = AsyncRemovalDiagnosticKind
            .nestedReasync
            .message
        
        let fixIt = FixItSpec(
            message: AsyncRemovalFixItKind.removeNestedReasync.message
        )
        
        let diagnostic = DiagnosticSpec(
            message:    message,
            line:       6,
            column:     9,
            severity:   .warning,
            fixIts:     [fixIt]
        )
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            diagnostics:        [diagnostic],
            macroSpecs:         macroSpecs
        )
    }
}
