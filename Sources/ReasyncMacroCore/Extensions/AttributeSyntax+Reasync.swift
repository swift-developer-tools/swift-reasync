//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import SwiftSyntax



extension AttributeSyntax
{
    /// Whether this attribute is `@Reasync`.
    ///
    /// This matches both `@Reasync` and `@Module.Reasync`.
    internal var isReasync: Bool
    {
        return self.hasSimpleName("Reasync")
    }
    
    
    
    /// Whether this attribute is `@Sendable`.
    ///
    /// This matches both `@Sendable` and `@Module.Sendable`.
    internal var isSendable: Bool
    {
        return self.hasSimpleName("Sendable")
    }
    
    
    
    /// Whether this attribute is `@concurrent`.
    ///
    /// This matches both `@concurrent` and `@Module.concurrent`.
    internal var isConcurrent: Bool
    {
        return self.hasSimpleName("concurrent")
    }
    
    
    
    /// Whether this attribute is `@isolated(any)`.
    ///
    /// This matches both `@isolated(any)` and `@Module.isolated(any)`. It does
    /// not match any other form of `@isolated(...)`, if such a form is later
    /// introduced.
    internal var isIsolatedAny: Bool
    {
        guard self.hasSimpleName("isolated")
        else
        {
            return false
        }
        
        guard
            case let .argumentList(args) = self.arguments,
            args.count == 1,
            let first: LabeledExprSyntax = args.first,
            first.label == nil,
            let reference = first.expression.as(DeclReferenceExprSyntax.self),
            reference.baseName.text == "any"
        else
        {
            return false
        }
        
        return true
    }
    
    
    
    // MARK: - Support
    
    /// Whether the attribute's name (excluding any module qualifier) matches
    /// the given simple name.
    /// - Parameter simpleName: The simple name to match.
    /// - Returns: Whether the attribute's name (excluding any module
    /// qualifier) matches the given simple name
    fileprivate func hasSimpleName(
        _ simpleName: String
    ) -> Bool
    {
        if let identifier = self.attributeName.as(IdentifierTypeSyntax.self)
        {
            return identifier.name.text == simpleName
        }
        
        if let member = self.attributeName.as(MemberTypeSyntax.self)
        {
            return member.name.text == simpleName
        }
        
        return false
    }
}
