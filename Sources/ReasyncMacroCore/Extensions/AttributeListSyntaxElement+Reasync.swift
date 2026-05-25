//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import SwiftSyntax



extension AttributeListSyntax.Element
{
    /// Whether this attribute must be removed from a function declaration
    /// when generating the synchronous peer of an `async` function.
    internal var requiresRemovalOnFunctionDeclaration: Bool
    {
        guard case let .attribute(attr) = self
        else
        {
            return false
        }
        
        return attr.isReasync
            || attr.isConcurrent
    }
}
