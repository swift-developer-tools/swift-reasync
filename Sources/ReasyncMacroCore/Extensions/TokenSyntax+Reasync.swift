//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import SwiftSyntax



extension TokenSyntax
{
    /// The trivia that should replace this token when it is removed from
    /// between other tokens.
    ///
    /// This is the token's leading trivia, plus its trailing trivia with the
    /// leading run of whitespace removed. The leading whitespace of the
    /// trailing trivia is the separator between this token and the next; with
    /// this token gone, that separator is redundant: the previous token's
    /// trailing trivia already separates it from what comes after. The token's
    /// own leading trivia is preserved verbatim, because it may carry
    /// meaningful content such as comments that should survive between the
    /// previous token and the next.
    ///
    /// This rule is distinct from the rule used when removing elements from
    /// a list (for example, attributes or specifiers), where neighbors
    /// provide their own positioning and both sides' outer whitespace is
    /// removed. See
    /// ``AsyncRemovalRewriter/filtering(_:removingWhen:pendingTrivia:)``.
    internal var triviaForRemoval: Trivia
    {
        return self.leadingTrivia
            + self.trailingTrivia.triviaAfterLeadingWhitespace
    }
}
