//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import SwiftSyntax



extension DeclModifierSyntax
{
    /// Whether this is a `nonisolated(nonsending)` declaration modifier.
    internal var isNonisolatedNonsending: Bool
    {
        return self.name.text == "nonisolated"
            && self.detail?.detail.text == "nonsending"
    }
}
