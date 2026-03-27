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
    internal var reasyncAttrIndex: AttributeListSyntax.Index?
    {
        return attributes.firstIndex
        {
            element in
            
            guard case let .attribute(attr) = element
            else
            {
                return false
            }
            
            if let identifier = attr.attributeName
                .as(IdentifierTypeSyntax.self)
            {
                return identifier.name.text == "Reasync"
            }
            
            /// Handle `@ModuleName.Reasync()` as well.
            if let member = attr.attributeName
                .as(MemberTypeSyntax.self)
            {
                return member.name.text == "Reasync"
            }
            
            return false
        }
    }
    
    
    
    /// Whether the function declaration has an `@Reasync` attribute.
    internal var hasReasyncAttr: Bool
    {
        return reasyncAttrIndex != nil
    }
}
