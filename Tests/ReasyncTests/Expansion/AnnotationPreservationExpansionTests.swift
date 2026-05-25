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



internal final class AnnotationPreservationExpansionTests: XCTestCase
{
    func testNonConcurrencyAnnotationPreservationOnClosureParameters()
    {
        let baseAnnotations: [String] =
        [
            "@MainActor",
            "@escaping",
            "@autoclosure"
        ]
        
        let annotationSubsets: [[String]] = combinations(of: baseAnnotations)
        
        for annotations in annotationSubsets
        {
            let prefix: String = annotations.joined(separator: " ")
            
            let functionSource: String =
            """
            func run(
                _ body: \(prefix) () async -> Void
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
                _ body: \(prefix) () -> Void
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
    }
    
    
    
    func testNonConcurrencyAnnotationPreservationOnFunctionDeclaration()
    {
        let baseAttrs: [String] =
        [
            "@Sendable",
            "@MainActor",
            "@discardableResult"
        ]
        
        let baseModifiers: [String] =
        [
            "nonisolated",
            "open",
            "public",
            "internal",
            "fileprivate",
            "private"
        ]
        
        let attributeSubsets: [[String]]
            = [[]] + combinations(of: baseAttrs)
        
        let modifierSubsets: [[String]]
            = [[]] + combinations(of: baseModifiers)
        
        for attributes in attributeSubsets
        {
            for modifiers in modifierSubsets
            {
                if
                    attributes.isEmpty,
                    modifiers.isEmpty
                {
                    continue
                }
                
                let prefix: String = (attributes + modifiers)
                    .joined(separator: " ")
                
                let functionSource: String =
                """
                \(prefix)
                func run(
                    _ body: () async -> Void
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
                
                \(prefix)
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
        }
    }
    
    
    
    func testConcurrencyAnnotationPreservationOnNonClosureType()
    {
        let functionSource: String =
        """
        func run(
            _ someStruct        : @Sendable SomeStruct,
            _ array             : @Sendable Array<Int>,
            _ optional          : @Sendable Optional<Int>,
            _ someCollection    : @Sendable some Collection,
            _ anyCollection     : @Sendable any Collection
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
            _ someStruct        : @Sendable SomeStruct,
            _ array             : @Sendable Array<Int>,
            _ optional          : @Sendable Optional<Int>,
            _ someCollection    : @Sendable some Collection,
            _ anyCollection     : @Sendable any Collection
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
    
    
    
    func testIsolatedParameterPreservation()
    {
        let functionSource: String =
        """
        func run(
            _ actor: isolated SomeActor
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
            _ actor: isolated SomeActor
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
    
    
    
    func testConcurrencyAnnotationOnBodyLocalBindingPreservation()
    {
        let annotations: [String] =
        [
            "@Sendable",
            "@isolated(any)"
        ]
        
        for annotation in annotations
        {
            let functionSource: String =
            """
            func run() async
            {
                let handler: \(annotation) () -> Void = someHandler
                
                handler()
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
                let handler: \(annotation) () -> Void = someHandler

                handler()
            }
            """
            
            assertMacroExpansion(
                originalSource,
                expandedSource:     expandedSource,
                macroSpecs:         macroSpecs
            )
        }
    }
    
    
    
    func testSendingOwnershipModifierParamPreservation()
    {
        let ownershipModifiers: [String] =
        [
            "inout",
            "consuming",
            "borrowing"
        ]
        
        for ownershipModifier in ownershipModifiers
        {
            let functionSource: String =
            """
            func run(
                _ box: \(ownershipModifier) sending Box
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
                _ box: \(ownershipModifier) sending Box
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
    }
}
