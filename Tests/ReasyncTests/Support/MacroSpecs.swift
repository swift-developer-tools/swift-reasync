//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

@testable import ReasyncMacro
import SwiftSyntaxMacroExpansion



internal let macroSpecs: [String : MacroSpec] =
[
    "Reasync": MacroSpec(
        type:           ReasyncMacro.ReasyncPeerMacro.self,
        conformances:   ["Reasync"]
    )
]
