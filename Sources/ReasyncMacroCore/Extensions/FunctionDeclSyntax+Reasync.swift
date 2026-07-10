//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import SwiftSyntax



extension FunctionDeclSyntax
{
    /// The index of the `@Reasync` attribute in the attribute list of the
    /// function declaration.
    internal var reasyncAttributeIndex: AttributeListSyntax.Index?
    {
        return self.attributes.firstIndex
        {
            element in
            
            guard case let .attribute(attr) = element
            else
            {
                return false
            }
            
            return attr.isReasync
        }
    }
    
    
    
    /// The indentation prefix that the macro expansion machinery will add to
    /// every newline-prefixed line of the generated peer when splicing it back
    /// into the source file at this declaration's attachment site.
    ///
    /// This returns `nil` if the trivia after the last newline does not have
    /// the expected shape (a single `.spaces` or `.tabs` piece). In that case,
    /// indentation trimming is skipped entirely. The peer is emitted without
    /// prior subtraction, which may produce visually-doubled indentation but
    /// preserves source trivia without damage.
    ///
    /// - Note: See ``IndentationTrimmingRewriter`` for more information.
    internal var leadingIndentationPrefix: TriviaPiece?
    {
        guard let firstToken: TokenSyntax
                = self.firstToken(viewMode: .sourceAccurate)
        else
        {
            return nil
        }
        
        let pieces: [TriviaPiece] = firstToken.leadingTrivia.pieces
        
        guard let lastNewlineIndex: Int = pieces
            .lastIndex(where: { $0.isNewline })
        else
        {
            return nil
        }
        
        let afterNewline: [TriviaPiece]
            = Array(pieces[(lastNewlineIndex + 1)...])
        
        guard afterNewline.count == 1
        else
        {
            return nil
        }
        
        let piece: TriviaPiece = afterNewline[0]
        
        switch piece
        {
            case
                .spaces,
                .tabs:
                
                return piece
                
            default:
                
                return nil
        }
    }
    
    
    
    /// Returns a copy of this function declaration with the attribute at the
    /// given index removed.
    ///
    /// The leading trivia of the removed attribute is transferred to the next
    /// remaining attribute, or to the first remaining modifier, or to the
    /// `func` keyword, in that order of preference.
    ///
    /// - Parameter index: The index at which to remove an attribute.
    /// - Returns: A copy of this function declaration with the attribute at
    /// the given index removed.
    internal func removingAttribute(
        at index: AttributeListSyntax.Index
    ) -> FunctionDeclSyntax
    {
        var copy: FunctionDeclSyntax = self
        
        let removedAttr: AttributeListSyntax.Element = copy.attributes[index]
        
        let removalTrivia: Trivia
            = removedAttr.leadingTrivia
            + removedAttr.trailingTrivia.triviaAfterLeadingWhitespace
        
        copy.attributes.remove(at: index)
        
        if var first: AttributeListSyntax.Element = copy.attributes.first
        {
            first.leadingTrivia.prepend(removalTrivia)
            
            copy.attributes[copy.attributes.startIndex] = first
        }
        else if var first: DeclModifierSyntax = copy.modifiers.first
        {
            first.leadingTrivia.prepend(removalTrivia)
            
            copy.modifiers[copy.modifiers.startIndex] = first
        }
        else
        {
            copy.funcKeyword.leadingTrivia.prepend(removalTrivia)
        }
        
        return copy
    }
}
