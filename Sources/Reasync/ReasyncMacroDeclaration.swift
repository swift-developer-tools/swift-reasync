//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

/// Produces a synchronous overload of an asynchronous function.
///
/// - Important: This is a purely syntactic transformation. The generated
/// function declaration must be valid in a synchronous context.
@attached(peer, names: overloaded)
public macro Reasync() = #externalMacro(
    module:     "ReasyncMacro",
    type:       "ReasyncPeerMacro"
)
