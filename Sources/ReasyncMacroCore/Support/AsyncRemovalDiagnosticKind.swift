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
    /// Synchronous function declarations are not supported.
    case requiresAsync
    
    /// The peer macro can only be attached to a function declaration.
    case reasyncOnNonFunction
    
    
    
    /// The diagnostic message.
    var message: String
    {
        switch self
        {
            case
                .requiresAsync,
                .reasyncOnNonFunction:
                
                return "@Reasync can only be applied to async functions"
        }
    }
    
    
    
    ///The diagnostic message’s type identifier.
    var diagnosticID: MessageID
    {
        let id: String
        
        switch self
        {
            case .requiresAsync         : id = "requiresAsync"
            case .reasyncOnNonFunction  : id = "reasyncOnNonFunction"
        }
        
        return MessageID(
            domain:     "swift-reasync",
            id:         id
        )
    }
    
    
    
    /// The diagnostic severity.
    var severity: DiagnosticSeverity
    {
        return .error
    }
}
