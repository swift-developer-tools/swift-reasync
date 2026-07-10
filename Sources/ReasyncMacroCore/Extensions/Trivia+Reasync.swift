//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import SwiftSyntax



extension Trivia
{
    
    /// A copy of this trivia with its leading run of whitespace pieces
    /// removed, preserving the rest of the trivia verbatim.
    ///
    /// When a syntactic element is removed from a list, its trailing trivia's
    /// leading whitespace is the visual separation between the removed element
    /// and the meaningful trivia that follows. With the element gone, that
    /// separation is redundant. The trailing portion of the trailing trivia,
    /// however, is the visual separation between the meaningful trivia and
    /// the next surviving element, which must be preserved.
    internal var triviaAfterLeadingWhitespace: Trivia
    {
        return Trivia(pieces: self.pieces
            .drop(while: { $0.isWhitespace })
        )
    }
    
    
    
    /// A copy of this trivia with its trailing run of whitespace pieces
    /// removed, preserving the rest of the trivia verbatim.
    ///
    /// When a syntactic element is removed from a list, its leading trivia's
    /// trailing whitespace is the visual separation that positioned the
    /// removed element on its own line (or after preceding spacing). With the
    /// element gone, that separation is redundant. The leading portion of the
    /// leading trivia, however, may contain meaningful pieces such as source
    /// comments, which must be preserved on a surviving sibling.
    internal var triviaBeforeTrailingWhitespace: Trivia
    {
        return Trivia(pieces: self.pieces
            .reversed()
            .drop(while: { $0.isWhitespace })
            .reversed()
        )
    }
    
    
    
    /// Prepends `prefix` to this trivia, collapsing the boundary newline if
    /// both `prefix` ends with one and this trivia begins with one.
    ///
    /// When trivia from a removed element is merged with the leading trivia of
    /// a surviving element, the removed element's trailing newline (which
    /// terminated its own source line) becomes redundant if the surviving
    /// element's leading trivia already provides one. Collapsing the boundary
    /// newline prevents the merge from introducing a spurious blank line.
    ///
    /// - Parameter prefix: The trivia to prepend.
    internal mutating func prepend(
        _ prefix: Trivia
    )
    {
        if
            prefix.pieces.last?.isNewline == true,
            self.pieces.first?.isNewline == true
        {
            self = Trivia(pieces: prefix.pieces.dropLast()) + self
        }
        else
        {
            self = prefix + self
        }
    }
}
