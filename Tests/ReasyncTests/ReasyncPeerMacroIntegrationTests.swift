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



internal final class ReasyncPeerMacroIntegrationTests: XCTestCase
{
    func testDoubleAsync() async
    {
        let result: Int = await double(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testDoubleSync()
    {
        let result: Int = double(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testQuadrupleAsync() async
    {
        let result: Int = await quadruple(5)
        
        XCTAssertEqual(result, 20)
    }
    
    
    
    func testQuadrupleSync()
    {
        let result: Int = quadruple(5)
        
        XCTAssertEqual(result, 20)
    }
    
    
    
    func testIncrementNoThrowAsync() async throws
    {
        let result: Int = try await increment(5, throw: false)
        
        XCTAssertEqual(result, 6)
    }
    
    
    
    func testIncrementNoThrowSync() throws
    {
        let result: Int = try increment(5, throw: false)
        
        XCTAssertEqual(result, 6)
    }
    
    
    
    func testIncrementThrowAsync() async throws
    {
        do
        {
            _ = try await increment(5, throw: true)

            XCTFail("Expected thrown error")
        }
        catch
        {
            XCTAssertNotNil(error as? TestError)
        }
    }
    
    
    
    func testIncrementThrowSync() throws
    {
        do
        {
            _ = try increment(5, throw: true)

            XCTFail("Expected thrown error")
        }
        catch
        {
            XCTAssertNotNil(error as? TestError)
        }
    }
    
    
    
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
    
    
    
    func testApplyClosureAsync() async
    {
        let result: Int = await applyClosure(10)
        
        XCTAssertEqual(result, 20)
    }
    
    
    
    func testApplyClosureSync()
    {
        let result: Int = applyClosure(10)
        
        XCTAssertEqual(result, 20)
    }
    
    
    
    func testThrowsTestErrorAsync() async throws
    {
        do
        {
            try await throwsTestError()
            
            XCTFail("Expected thrown error")
        }
        catch
        {
            // Do nothing.
        }
    }
    
    
    
    func testThrowsTestErrorSync() throws
    {
        do
        {
            try throwsTestError()
            
            XCTFail("Expected thrown error")
        }
        catch
        {
            // Do nothing.
        }
    }
}



// MARK: - Support

private struct TestError: Error { }



@Reasync
private func double(
    _ value: Int
) async -> Int
{
    return value * 2
}



@Reasync
private func quadruple(
    _ value: Int
) async -> Int
{
    let result: Int = await double(value)
    
    return result * 2
}



@Reasync
private func increment(
    _       value       : Int,
    throw   shouldThrow : Bool
) async throws -> Int
{
    if shouldThrow
    {
        throw TestError()
    }
    
    return value + 1
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



@Reasync
private func applyClosure(
    _ value: Int
) async -> Int
{
    let result = await
    {
        () async -> Int in
        
        return value * 2
    }()
    
    return result
}



@Reasync
@discardableResult
private func throwsTestError() async throws(TestError) -> Int
{
    throw TestError()
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




