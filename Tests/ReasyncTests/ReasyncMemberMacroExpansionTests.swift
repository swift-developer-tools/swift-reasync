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



internal final class ReasyncMemberMacroExpansionTests: XCTestCase
{
    private static let macroSpecs: [String : MacroSpec] =
    [
        "ReasyncMembers": MacroSpec(
            type:           ReasyncMacro.ReasyncMemberMacro.self,
            conformances:   ["ReasyncMembers"]
        )
    ]
    
    
    
    func testReasyncMembersExpansionOnStructWithAsyncFunction()
    {
        let functionSource: String =
        """
        func double(_ value: Int) async -> Int { return value * 2 }
        """
        
        let originalSource: String =
        """
        @ReasyncMembers
        struct SomeStruct 
        {
            \(functionSource)
        }
        """
        
        let expandedSource: String =
        """
        struct SomeStruct 
        {
            \(functionSource)
        
            func double(_ value: Int) -> Int {
                return value * 2
            }
        }
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     expandedSource,
            macroSpecs:         Self.macroSpecs
        )
    }
    
    
    
    func testReasyncMembersExpansionOnStructWithSyncFunction()
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
        @ReasyncMembers
        \(structSource)
        """
        
        assertMacroExpansion(
            originalSource,
            expandedSource:     structSource,
            macroSpecs:         Self.macroSpecs
        )
    }
    
    
    
    func testReasyncMembersExpansionOnProtocol()
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
        @ReasyncMembers
        \(protocolSource)
        """
        
        let message: String = AsyncRemovalDiagnosticKind
            .protocolNotSupported
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
