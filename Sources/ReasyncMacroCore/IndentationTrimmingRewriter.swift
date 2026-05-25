//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import SwiftSyntax



/// A syntax rewriter that trims a fixed indentation prefix from every line
/// of leading trivia in a syntax tree.
///
/// This rewriter is the inverse of the indentation that the macro expansion
/// machinery adds to a peer declaration at splice time. When the macro
/// expansion machinery splices a peer back into the source file, it adds the
/// attachment site's leading indentation to every line of the peer that
/// follows a newline. When the peer is produced by cloning and mutating the
/// source declaration's syntax tree, every interior line of the peer already
/// carries the source's indentation baked into the leading trivia of each
/// token. Without normalization, the splice produces doubled indentation on
/// every interior line of the peer.
///
/// This rewriter visits every token in the tree and, for each newline piece
/// in the token's leading trivia, subtracts the prefix from the whitespace
/// piece immediately following the newline, if any. Whitespace pieces that
/// do not follow a newline are not modified: such pieces represent
/// continuation from the previous token's line and are not re-indented by the
/// splice machinery. Trailing trivia is not modified, since trailing trivia
/// rarely contains a newline-then-indentation pattern, and modifying it could
/// silently drop intended spacing.
///
/// The trimming is structural. The prefix piece's kind (`.spaces` or `.tabs`)
/// must match the line's leading whitespace piece's kind, and the line's
/// piece must have a count greater than or equal to the prefix's count. When
/// both conditions are met, the prefix's count is subtracted; the resulting
/// piece is included in the output only if its remaining count is non-zero.
/// When either condition fails, the line's piece is left unmodified. This
/// conservatively avoids damaging trivia that does not match the expected
/// indentation shape.
internal final class IndentationTrimmingRewriter: SyntaxRewriter
{
    /// The indentation piece to trim from each post-newline whitespace run.
    private let prefix      : TriviaPiece
    
    /// The count of whitespace units in the prefix piece.
    ///
    /// This is cached at initialization to avoid re-extracting it for every
    /// visited token.
    private let prefixCount : Int
    
    
    
    /// Initializes an ``IndentationTrimmingRewriter`` instance from the given
    /// indentation piece.
    internal init(
        prefix: TriviaPiece
    )
    {
        self.prefix = prefix
        
        switch prefix
        {
            case let .spaces(count) : self.prefixCount  = count
            case let .tabs(count)   : self.prefixCount  = count
            default                 : self.prefixCount  = 0
        }
        
        super.init()
    }
    
    
    
    // MARK: - Visit
    
    /// Visits the given token node.
    ///
    /// This trims the prefix from every post-newline whitespace run in the
    /// token's leading trivia. Trailing trivia is not modified.
    ///
    /// - Parameter token: The token to visit.
    /// - Returns: A token node.
    override func visit(
        _ token: TokenSyntax
    ) -> TokenSyntax
    {
        guard self.prefixCount > 0
        else
        {
            return token
        }
        
        var result: TokenSyntax = token
        
        result.leadingTrivia = trimmingPrefix(from: token.leadingTrivia)
        
        return result
    }
    
    
    
    // MARK: - Trim
    
    /// Returns a copy of the given trivia with the prefix trimmed from every
    /// post-newline whitespace run.
    ///
    /// The trivia is walked piece by piece. Each piece is incldued in the
    /// output as-is, except when:
    ///
    /// - The previous emitted piece is a newline.
    /// - The current piece is a whitespace piece (`.spaces` or `.tabs`) of
    /// the same kind as the prefix.
    /// - The current piece's count is at least the prefix's count.
    ///
    /// When all three conditions are met, the current piece's count is
    /// reduced by the prefix's count. If the reduced count is positive, the
    /// reduced piece is emitted; if the reduced count is zero, the piece is
    /// omitted entirely.
    ///
    /// - Parameter trivia: The trivia to trim.
    /// - Returns: The trimmed trivia.
    private func trimmingPrefix(
        from trivia: Trivia
    ) -> Trivia
    {
        var result              : [TriviaPiece]     = []
        var previousWasNewline  : Bool              = false
        
        for piece in trivia.pieces
        {
            if previousWasNewline
            {
                if let trimmed: TriviaPiece = trimmingPrefix(from: piece)
                {
                    result.append(trimmed)
                }
                
                /// Otherwise, the piece's count exactly matched the prefix,
                /// so it is omitted entirely.
            }
            else
            {
                result.append(piece)
            }
            
            previousWasNewline = piece.isNewline
        }
        
        return Trivia(pieces: result)
    }
    
    
    
    /// Returns the given piece with the prefix's count subtracted, or `nil`
    /// if the result would be zero-count.
    ///
    /// This returns the piece unchanged if it does not match the prefix's
    /// kind, or if its count is less than the prefix's count.
    ///
    /// - Parameter piece: The piece to trim.
    /// - Returns: The trimmed piece, or `nil` if the piece is consumed
    /// entirely.
    private func trimmingPrefix(
        from piece: TriviaPiece
    ) -> TriviaPiece?
    {
        switch (prefix, piece)
        {
            case let (.spaces, .spaces(count)):
                
                guard count >= prefixCount
                else
                {
                    return piece
                }
                
                let remaining: Int = count - prefixCount
                
                return remaining > 0
                    ? .spaces(remaining)
                    : nil
                
            case let (.tabs, .tabs(count)):
                
                guard count >= prefixCount
                else
                {
                    return piece
                }
                
                let remaining: Int = count - prefixCount
                
                return remaining > 0
                    ? .tabs(remaining)
                    : nil
                
            default:
                
                return piece
        }
    }
}
