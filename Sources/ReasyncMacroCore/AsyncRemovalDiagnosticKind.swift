//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import SwiftDiagnostics



/// Diagnostics for macro expansion.
internal enum AsyncRemovalDiagnosticKind: DiagnosticMessage
{
    /// `@Reasync` is attached to a synchronous function declaration.
    case requiresAsync
    
    /// `@Reasync` is attached to a non-function declaration.
    case reasyncOnNonFunction
    
    /// `@Reasync` is attached to a function requirement within a protocol.
    case reasyncOnProtocolRequirement
    
    /// `@Reasync` is attached to a function declaration nested within an
    /// enclosing `@Reasync` function declaration.
    case nestedReasync
    
    
    
    /// The diagnostic message.
    var message: String
    {
        switch self
        {
            case
                .requiresAsync,
                .reasyncOnNonFunction:
                
                return "'@Reasync' can only be applied to async functions"
                
            case .reasyncOnProtocolRequirement:
                
                return "'@Reasync' cannot be applied to protocol requirements"
                
            case .nestedReasync:
                
                return "Nested function declarations within an '@Reasync'"
                    + " function are already transformed by the enclosing macro"
        }
    }
    
    
    
    ///The diagnostic message’s type identifier.
    var diagnosticID: MessageID
    {
        let id: String
        
        switch self
        {
            case .requiresAsync                 : id = "requiresAsync"
            case .reasyncOnNonFunction          : id = "reasyncOnNonFunction"
            case .reasyncOnProtocolRequirement  : id = "reasyncOnProtocolRequirement"
            case .nestedReasync                 : id = "nestedReasync"
        }
        
        return MessageID(
            domain:     "swift-reasync",
            id:         id
        )
    }
    
    
    
    /// The diagnostic severity.
    var severity: DiagnosticSeverity
    {
        switch self
        {
            case
                .requiresAsync,
                .reasyncOnNonFunction,
                .reasyncOnProtocolRequirement:
                
                return .error
                
            case .nestedReasync:
                
                return .warning
        }
    }
}
