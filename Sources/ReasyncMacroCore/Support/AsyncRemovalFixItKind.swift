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
    case useReasyncMembers
    
    
    
    /// The fix-it message.
    var message: String
    {
        switch self
        {
            case .useReasyncMembers: return "Use '@ReasyncMembers'"
        }
    }
    
    
    
    ///The fix-it message’s type identifier.
    var fixItID: MessageID
    {
        let id: String
        
        switch self
        {
            case .useReasyncMembers: id = "useReasyncMembers"
        }
        
        return MessageID(
            domain:     "swift-reasync",
            id:         id
        )
    }
}
