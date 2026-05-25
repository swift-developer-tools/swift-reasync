//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import SwiftDiagnostics



/// Fix-its for macro expansion.
internal enum AsyncRemovalFixItKind: FixItMessage
{
    /// Remove a redundant nested `@Reasync` attribute.
    case removeNestedReasync
    
    
    
    /// The fix-it message.
    var message: String
    {
        switch self
        {
            case .removeNestedReasync: return "Remove '@Reasync'"
        }
    }
    
    
    
    ///The fix-it message’s type identifier.
    var fixItID: MessageID
    {
        let id: String
        
        switch self
        {
            case .removeNestedReasync: id = "removeNestedReasync"
        }
        
        return MessageID(
            domain:     "swift-reasync",
            id:         id
        )
    }
}
