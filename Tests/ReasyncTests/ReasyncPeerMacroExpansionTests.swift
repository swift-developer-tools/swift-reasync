//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

@testable import ReasyncMacroCore
@testable import ReasyncMacro
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosTestSupport
import XCTest



internal final class ReasyncPeerMacroExpansionTests: XCTestCase
{
    private static let macroSpecs: [String : MacroSpec] =
    [
        "Reasync": MacroSpec(
            type:           ReasyncMacro.ReasyncPeerMacro.self,
            conformances:   ["Reasync"]
        )
    ]
    
    
    
    func testReasyncPeerExpansionOnAsyncFunction()
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
            macroSpecs:         Self.macroSpecs
        )
    }
    
    
    
    func testReasyncPeerExpansionOnSyncFunction()
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
            column:     1
        )
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     functionSource,
            diagnostics:        [diagnostic],
            macroSpecs:         Self.macroSpecs
        )
    }
    
    
    
    func testReasyncPeerExpansionOnStruct()
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
        
        let fixIt = FixItSpec(
            message: AsyncRemovalFixItKind.useReasyncMembers.message
        )
        
        let diagnostic = DiagnosticSpec(
            message:    message,
            line:       1,
            column:     1,
            fixIts:     [fixIt]
        )
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     structSource,
            diagnostics:        [diagnostic],
            macroSpecs:         Self.macroSpecs
        )
    }
    
    
    
    func testReasyncPeerExpansionOnProtocol()
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
            column:     1
        )
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     protocolSource,
            diagnostics:        [diagnostic],
            macroSpecs:         Self.macroSpecs
        )
    }
}
