//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import ReasyncMacroCore
import SwiftCompilerPlugin
import SwiftSyntaxMacros



@main
struct ReasyncMacroPlugin: CompilerPlugin
{
    let providingMacros: [any Macro.Type] =
    [
        ReasyncMemberMacro.self,
        ReasyncPeerMacro.self
    ]
}
