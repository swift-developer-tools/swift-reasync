//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import SwiftSyntax



extension TypeSpecifierListSyntax.Element
{
    /// Whether this is a `nonisolated(nonsending)` type specifier.
    internal var isNonisolatedNonsending: Bool
    {
        guard case let .nonisolatedTypeSpecifier(specifier) = self
        else
        {
            return false
        }
        
        return specifier.argument?.nonsendingKeyword.text == "nonsending"
    }
}
