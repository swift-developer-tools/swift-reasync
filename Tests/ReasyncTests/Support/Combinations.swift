//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

/// Returns all combinations of the given elements, excluding the empty
/// array.
/// - Parameter elements: The elements to combine.
/// - Returns: All combinations of the given elements.
internal func combinations<T>(
    of elements: [T]
) -> [[T]]
{
    /// Start at one to exclude the empty array.
    return (1..<(1 << elements.count)).map
    {
        (mask: Int) in
        
        return elements.enumerated().compactMap
        {
            (index: Int, element: T) in
            
            return (mask & (1 << index)) != 0
                ? element
                : nil
        }
    }
}
