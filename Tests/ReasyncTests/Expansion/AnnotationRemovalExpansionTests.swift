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



internal final class AnnotationRemovalExpansionTests: XCTestCase
{
    func testConcurrencyAnnotationRemovalFromClosureParameters()
    {
        let baseAnnotations: [String] =
        [
            "@Sendable",
            "@isolated(any)",
            "@concurrent",
            "nonisolated(nonsending)"
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
    
    
    
    func testConcurrencyAnnotationRemovalFromFunctionDeclaration()
    {
        let baseAnnotations: [String] =
        [
            "@concurrent",
            "nonisolated(nonsending)"
        ]
        
        let annotationSubsets: [[String]] = combinations(of: baseAnnotations)
        
        for annotations in annotationSubsets
        {
            let prefix: String = annotations.joined(separator: " ")
            
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
    
    
    
    func testModuleQualifiedSendableRemovalFromClosureType()
    {
        let functionSource: String =
        """
        func run(
            _ body: @Swift.Sendable () async -> Void
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
    
    
    
    func testConcurrencyAnnotationOnBodyLocalBindingRemoval()
    {
        let annotations: [String] =
        [
            "nonisolated(nonsending)",
            "@concurrent"
        ]
        
        for annotation in annotations
        {
            let functionSource: String =
            """
            func run() async
            {
                let handler: \(annotation) () async -> Void = someHandler
                
                await handler()
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
                let handler: () -> Void = someHandler

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
}
