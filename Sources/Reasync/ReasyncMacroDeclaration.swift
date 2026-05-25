//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

/// Generates a synchronous overload of an asynchronous function.
///
/// The `@Reasync` macro is attached to an `async` function declaration. At
/// compile time, it produces a synchronous overload of the function by
/// removing `async` and `await` from the declaration and body. The
/// asynchronous declaration remains the single source of truth, and Swift's
/// overload resolution selects the appropriate version at each call site.
///
/// The transformation is purely syntactic. The macro removes:
///
/// - `async` and `await` wherever they appear, including in the function
/// signature, in `await` expressions, in `async let` bindings (which become
/// `let` bindings), and in `for await` loops (which become `for` loops).
/// - `@Sendable`, `@isolated(any)`, `@concurrent`, and
/// `nonisolated(nonsending)` from closure parameter types.
/// - `nonisolated(nonsending)` and `@concurrent` from the function declaration
/// itself.
///
/// All other annotations, including `sending`, global actor isolation, and
/// typed throws, are preserved on the generated peer.
///
/// Nested function declarations within the annotated function are subject to
/// the same transformation. Annotating a nested function with `@Reasync` has
/// no additional effect and produces a warning, since the enclosing macro
/// already transforms it.
///
/// The macro does not analyze the function body. If the body contains
/// constructs that are inherently asynchronous, such as calls to
/// actor-isolated methods or `async`-only APIs, the generated overload will
/// fail to compile, and the compiler will report the error at the invalid
/// expression in the expanded source.
///
/// - Important: `@Reasync` removes `@Sendable` from closure parameter types
/// in the generated peer. This matches the common case, in which `@Sendable`
/// was required only because the asynchronous body crossed an isolation
/// boundary. If `@Sendable` was applied for reasons unrelated to the body's
/// use of the closure, the synchronous overload should be written by hand
/// instead of using `@Reasync`.
@attached(peer, names: overloaded)
public macro Reasync() = #externalMacro(
    module:     "ReasyncMacro",
    type:       "ReasyncPeerMacro"
)
