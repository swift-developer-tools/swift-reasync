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



internal final class AnnotationMixedExpansionTests: XCTestCase
{
    func testCombinedConcurrencyRemovalAndPreservationOnClosureParameters()
    {
        let removedAttrs: [String] =
        [
            "@Sendable",
            "@isolated(any)",
            "@concurrent"
        ]
        
        let preservedAttrs: [String] =
        [
            "@MainActor",
            "@escaping",
            "@autoclosure"
        ]
        
        let removedAttrSubsets: [[String]]
            = [[]] + combinations(of: removedAttrs)
        
        let preservedAttrSubsets: [[String]]
            = [[]] + combinations(of: preservedAttrs)
        
        /// `nonisolated(nonsending)` is a specifier, not an attribute, and
        /// syntactically precedes the attribute list. Handle it separately
        /// to keep the generated source gramatically valid.
        for includeNonsending in [false, true]
        {
            for removedAttrs in removedAttrSubsets
            {
                for preservedAttrs in preservedAttrSubsets
                {
                    if
                        !includeNonsending,
                        removedAttrs.isEmpty,
                        preservedAttrs.isEmpty
                    {
                        continue
                    }
                    
                    
                    
                    let nonsendingPrefix: String = includeNonsending
                        ? "nonisolated(nonsending)"
                        : ""
                    
                    let sourcePrefix: String = nonsendingPrefix
                        + (removedAttrs + preservedAttrs)
                            .joined(separator: " ")
                    
                    let expandedPrefix: String
                        = preservedAttrs.joined(separator: " ")
                    
                    let expandedClosurePrefix: String = expandedPrefix.isEmpty
                        ? ""
                        : "\(expandedPrefix) "
                    
                    
                    
                    let functionSource: String =
                    """
                    func run(
                        _ body: \(sourcePrefix) () async -> Void
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
                        _ body: \(expandedClosurePrefix)() -> Void
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
    }
    
    
    
    func testCombinedConcurrencyRemovalAndPreservationOnFunctionDeclaration()
    {
        let removedAttrs: [String] =
        [
            "@concurrent"
        ]
        
        let removedModifiers: [String] =
        [
            "nonisolated(nonsending)"
        ]
        
        let preservedAttrs: [String] =
        [
            "@Sendable",
            "@MainActor",
            "@discardableResult"
        ]
        
        let preservedModifiers: [String] =
        [
            "nonisolated",
            "open",
            "public",
            "internal",
            "fileprivate",
            "private"
        ]
        
        let removedAttrSubsets: [[String]]
            = [[]] + combinations(of: removedAttrs)
        
        let removedModifierSubsets: [[String]]
            = [[]] + combinations(of: removedModifiers)
        
        let preservedAttrSubsets: [[String]]
            = [[]] + combinations(of: preservedAttrs)
        
        let preservedModifierSubsets: [[String]]
            = [[]] + combinations(of: preservedModifiers)
        
        for removedAttrs in removedAttrSubsets
        {
            for removedModifers in removedModifierSubsets
            {
                for preservedAttrs in preservedAttrSubsets
                {
                    for preservedModifiers in preservedModifierSubsets
                    {
                        if
                            removedAttrs.isEmpty,
                            removedModifers.isEmpty,
                            preservedAttrs.isEmpty,
                            preservedModifiers.isEmpty
                        {
                            continue
                        }
                        
                        
                        
                        let sourceAttrs: [String]
                            = removedAttrs + preservedAttrs
                        
                        let sourceModifiers: [String]
                            = removedModifers + preservedModifiers
                        
                        let sourcePrefix: String
                            = (sourceAttrs + sourceModifiers)
                                .joined(separator: " ")
                        
                        let expandedPrefix: String
                            = (preservedAttrs + preservedModifiers)
                                .joined(separator: " ")
                        
                        let expandedDeclPrefix: String = expandedPrefix.isEmpty
                            ? ""
                            : "\(expandedPrefix)\n"
                        
                        
                        
                        let functionSource: String =
                        """
                        \(sourcePrefix)
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
                        
                        \(expandedDeclPrefix)func run(
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
        }
    }
}
