//===----------------------------------------------------------------------===//
//
// This source file is part of the swift-reasync open source project.
//
// Copyright (c) Margins Technologies LLC.
// Licensed under the Apache License, Version 2.0.
//
//===----------------------------------------------------------------------===//

import Reasync
import XCTest



internal final class BodyTransformationIntegrationTests: XCTestCase
{
    func testDoubleThenAddAsync() async
    {
        let result: Int = await doubleThenAdd(5, 5)
        
        XCTAssertEqual(result, 20)
    }
    
    
    
    func testDoubleThenAddSync()
    {
        let result: Int = doubleThenAdd(5, 5)
        
        XCTAssertEqual(result, 20)
    }
    
    
    
    func testSumNoTryAsync() async
    {
        let result: Int = await sum([5, 5], useTry: false)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testSumNoTrySync()
    {
        let result: Int = sum([5, 5], useTry: false)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testSumTryAsync() async
    {
        let result: Int = await sum([5, 5], useTry: true)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testSumTrySync()
    {
        let result: Int = sum([5, 5], useTry: true)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testTransformAsync() async throws
    {
        let result: [Int] = try await transform(
            [1, 2, 3],
            by: { value async in value * 10 }
        )
        
        XCTAssertEqual(result, [10, 20, 30])
    }
    
    
    
    func testTransformSync() throws
    {
        let result: [Int] = try transform(
            [1, 2, 3],
            by: { value in value * 10 }
        )
        
        XCTAssertEqual(result, [10, 20, 30])
    }
}



// MARK: - Support

@Reasync
private func double(
    _ value: Int
) async -> Int
{
    return value * 2
}



@Reasync
private func doubleThenAdd(
    _ a: Int,
    _ b: Int
) async -> Int
{
    async let x : Int   = double(a)
    async let y : Int   = double(b)
    
    return await x + y
}



/// A sequence used to test `for await` → `for` transformation.
private struct DualSequence<Element>: Sequence, AsyncSequence
{
    let elements: [Element]
    
    func makeIterator() -> Array<Element>.Iterator
    {
        return elements.makeIterator()
    }
    
    func makeAsyncIterator() -> AsyncIterator
    {
        return AsyncIterator(elements: elements)
    }
    
    struct AsyncIterator: AsyncIteratorProtocol
    {
        let elements    : [Element]
        var index       : Int       = 0
        
        mutating func next() async -> Element?
        {
            guard index < elements.count
            else
            {
                return nil
            }
            
            defer
            {
                index += 1
            }
            
            return elements[index]
        }
    }
}



@Reasync
private func sum(
    _ elements  : [Int],
    useTry      : Bool
) async -> Int
{
    let sequence = DualSequence(elements: elements)
    
    var sum: Int = 0
    
    if useTry
    {
        for try await element in sequence
        {
            sum += element
        }
    }
    else
    {
        for await element in sequence
        {
            sum += element
        }
    }
    
    return sum
}



@Reasync
private func transform(
    _   values      : [Int],
    by  transform   : (Int) async throws -> Int
) async throws -> [Int]
{
    var results: [Int] = []
    
    for value in values
    {
        results.append(try await transform(value))
    }
    
    return results
}
