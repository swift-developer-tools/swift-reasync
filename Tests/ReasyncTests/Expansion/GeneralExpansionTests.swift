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



internal final class GeneralExpansionTests: XCTestCase
{
    func testOnAsyncFunctionDeclaration()
    {
        let functionSource: String =
        """
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
    
    
    
    func testOnRethrowsFunction()
    {
        let functionSource: String =
        """
        func run(_ body: () async throws -> Void) async rethrows
        {
            try await body()
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
        
        func run(_ body: () throws -> Void) rethrows
        {
            try body()
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testOnTypedThrowsFunction()
    {
        let functionSource: String =
        """
        func run() async throws(SomeError)
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
        
        func run() throws(SomeError)
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
    
    
    
    func testOnSyncFunctionDeclaration()
    {
        let functionSource: String =
        """
        func double(_ value: Int) -> Int { return value * 2 }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(functionSource)
        """
        
        let message: String = AsyncRemovalDiagnosticKind
            .requiresAsync
            .message
        
        let diagnostic = DiagnosticSpec(
            message:    message,
            line:       1,
            column:     1,
            severity:   .error
        )
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     functionSource,
            diagnostics:        [diagnostic],
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testOnStructDeclaration()
    {
        let structSource: String =
        """
        struct SomeStruct 
        {
            func double(_ value: Int) -> Int { return value * 2 }
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(structSource)
        """
        
        let message: String = AsyncRemovalDiagnosticKind
            .reasyncOnNonFunction
            .message
        
        let diagnostic = DiagnosticSpec(
            message:    message,
            line:       1,
            column:     1,
            severity:   .error
        )
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     structSource,
            diagnostics:        [diagnostic],
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testOnProtocolDeclaration()
    {
        let protocolSource: String =
        """
        protocol SomeProtocol
        {
            func double(_ value: Int) async -> Int
        }
        """
        
        let originalSource: String =
        """
        @Reasync
        \(protocolSource)
        """
        
        let message: String = AsyncRemovalDiagnosticKind
            .reasyncOnNonFunction
            .message
        
        let diagnostic = DiagnosticSpec(
            message:    message,
            line:       1,
            column:     1,
            severity:   .error
        )
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     protocolSource,
            diagnostics:        [diagnostic],
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testOnProtocolFunctionRequirement()
    {
        let functionSource: String =
        """
        func double(_ value: Int) async -> Int
        """
        
        let originalSource: String =
        """
        protocol SomeProtocol
        {
            @Reasync
            \(functionSource)
        }
        """
        
        let expandedSource: String =
        """
        protocol SomeProtocol
        {
            \(functionSource)
        }
        """
        
        let message: String = AsyncRemovalDiagnosticKind
            .reasyncOnProtocolRequirement
            .message
        
        let diagnostic = DiagnosticSpec(
            message:    message,
            line:       3,
            column:     5,
            severity:   .error
        )
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            diagnostics:        [diagnostic],
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testOnSyncProtocolFunctionRequirement()
    {
        let functionSource: String =
        """
        func double(_ value: Int) -> Int
        """
        
        let originalSource: String =
        """
        protocol SomeProtocol
        {
            @Reasync
            \(functionSource)
        }
        """
        
        let expandedSource: String =
        """
        protocol SomeProtocol
        {
            \(functionSource)
        }
        """
        
        let message: String = AsyncRemovalDiagnosticKind
            .requiresAsync
            .message
        
        let diagnostic = DiagnosticSpec(
            message:    message,
            line:       3,
            column:     5,
            severity:   .error
        )
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            diagnostics:        [diagnostic],
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testOnComputedProperty()
    {
        let propertySource: String =
        """
        var someProperty: Int { get async { 0 } }
        """
        
        let structSource: String =
        """
        struct SomeStruct
        {
            \(propertySource)
        }
        """
        
        let originalSource: String =
        """
        struct SomeStruct
        {
            @Reasync
            \(propertySource)
        }
        """
        
        let message: String = AsyncRemovalDiagnosticKind
            .reasyncOnNonFunction
            .message
        
        let diagnostic = DiagnosticSpec(
            message:    message,
            line:       3,
            column:     5,
            severity:   .error
        )
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     structSource,
            diagnostics:        [diagnostic],
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAsyncRemovalFromClosureExpressionBody()
    {
        let functionSource: String =
        """
        func run() async
        {
            let result = await
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
    
    
    
    func testAwaitRemovalInBinaryExpression()
    {
        let functionSource: String =
        """
        func run() async -> Int
        {
            return 1 + await someFunction()
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
            return 1 + someFunction()
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAwaitRemovalInFunctionCallArgument()
    {
        let functionSource: String =
        """
        func run() async -> Int
        {
            return process(await someFunction())
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
            return process(someFunction())
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAsyncLetWithMultipleBindingsInOneDeclaration()
    {
        let functionSource: String =
        """
        func run() async
        {
            async let x: Int = 0, y: Int = 0
        
            return await x + y
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
            let x: Int = 0, y: Int = 0
        
            return x + y
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
    
    
    
    func testAsyncLetWithTupleDestructuring()
    {
        let functionSource: String =
        """
        func run() async
        {
            async let (x, y) = someTuple()
        
            return await x + y
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
            let (x, y) = someTuple()
        
            return x + y
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         macroSpecs
        )
    }
}
