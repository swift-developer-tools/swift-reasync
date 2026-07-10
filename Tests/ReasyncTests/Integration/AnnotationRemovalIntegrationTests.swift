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



internal final class AnnotationRemovalIntegrationTests: XCTestCase
{
    @MainActor
    func testSumWithSendableAsync() async
    {
        let result: Int = await sumWithSendable(
            10,
            20,
            using: { @Sendable value async in value * 2 }
        )
        
        XCTAssertEqual(result, 60)
    }
    
    
    
    func testSumWithSendableSync()
    {
        let result: Int = sumWithSendable(
            10,
            20,
            using: { value in value * 2 }
        )
        
        XCTAssertEqual(result, 60)
    }
    
    
    
    @MainActor
    func testNonisolatedNonsendingIncrementAsync() async
    {
        let box = Box(10)
        
        await nonisolatedNonsendingIncrement(box)
        
        XCTAssertEqual(box.value, 11)
    }
    
    
    
    @MainActor
    func testNonisolatedNonsendingIncrementSync()
    {
        let box = Box(10)
        
        nonisolatedNonsendingIncrement(box)
        
        XCTAssertEqual(box.value, 11)
    }
    
    
    
    func testConcurrentDoubleAsync() async
    {
        let result: Int = await concurrentDouble(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testConcurrentDoubleSync()
    {
        let result: Int = concurrentDouble(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    @MainActor
    func testRunIsolatedAsync() async
    {
        let box = Box(0)
        
        await runIsolated
        {
            @MainActor in
            
            /// Force suspension so the closure exercises its isolation.
            await Task.yield()
            
            box.value = 1
        }
        
        XCTAssertEqual(box.value, 1)
    }
    
    
    
    func testRunIsolatedSync()
    {
        let box = Box(0)
        
        runIsolated
        {
            box.value = 1
        }
        
        XCTAssertEqual(box.value, 1)
    }
    
    
    
    func testApplyConcurrentAsync() async
    {
        let result: Int = await applyConcurrent(
            5,
            using: { value async in value * 2 }
        )
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testApplyConcurrentSync()
    {
        let result: Int = applyConcurrent(
            5,
            using: { value in value * 2 }
        )
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    @MainActor
    func testRunOnCallerAsync() async
    {
        let box = Box(0)
        
        await runOnCaller
        {
            /// Force suspension so the closure exercises its isolation.
            await Task.yield()
            
            box.value = 1
        }
        
        XCTAssertEqual(box.value, 1)
    }
    
    
    
    func testRunOnCallerSync()
    {
        let box = Box(0)
        
        runOnCaller
        {
            box.value = 1
        }
        
        XCTAssertEqual(box.value, 1)
    }
}



// MARK: - Support

@Reasync
private func sumWithSendable(
    _       a       : Int,
    _       b       : Int,
    using   compute : @Sendable (Int) async -> Int
) async -> Int
{
    async let x : Int   = compute(a)
    async let y : Int   = compute(b)
    
    return await x + y
}



@Reasync
private nonisolated(nonsending) func nonisolatedNonsendingIncrement(
    _ box: Box
) async
{
    box.value += 1
}



@Reasync
@concurrent
private func concurrentDouble(
    _ value: Int
) async -> Int
{
    return value * 2
}



@Reasync
private func runIsolated(
    _ body: @isolated(any) () async -> Void
) async
{
    await body()
}



@Reasync
private func applyConcurrent(
    _       value       : Int,
    using   transform   : @concurrent (Int) async -> Int
) async -> Int
{
    return await transform(value)
}



@Reasync
private func runOnCaller(
    _ body: nonisolated(nonsending) () async -> Void
) async
{
    await body()
}
