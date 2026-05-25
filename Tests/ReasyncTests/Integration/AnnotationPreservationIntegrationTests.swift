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



internal final class AnnotationPreservationIntegrationTests: XCTestCase
{
    func testAcceptSendingAsync() async
    {
        let box = Box(10)
        
        await acceptSending(box)
    }
    
    
    
    func testAcceptSendingSync()
    {
        let box = Box(10)
        
        acceptSending(box)
    }
    
    
    
    func testProduceSendingAsync() async
    {
        let box: Box = await produceSending(10)
        
        XCTAssertEqual(box.value, 10)
    }
    
    
    
    func testProduceSendingSync()
    {
        let box: Box = produceSending(10)
        
        XCTAssertEqual(box.value, 10)
    }
    
    
    
    func testTransformSendingAsync() async
    {
        let box: Box = await transformSending(Box(10))
        
        XCTAssertEqual(box.value, 20)
    }
    
    
    
    func testTransformSendingSync()
    {
        let box: Box = transformSending(Box(10))
        
        XCTAssertEqual(box.value, 20)
    }
    
    
    
    @MainActor
    func testMainActorIncrementAsync() async
    {
        let box = Box(10)
        
        await mainActorIncrement(box)
        
        XCTAssertEqual(box.value, 11)
    }
    
    
    
    @MainActor
    func testMainActorIncrementSync()
    {
        let box = Box(10)
        
        mainActorIncrement(box)
        
        XCTAssertEqual(box.value, 11)
    }
    
    
    
    func testIsolatedIncrementAsync() async
    {
        let actor = TestActor()
        
        await isolatedIncrement(
            on:     actor,
            by:     5
        )
        
        let value: Int = await actor.value
        
        XCTAssertEqual(value, 5)
    }
    
    
    
    func testIsolatedIncrementSync() async
    {
        let actor = TestActor()
        
        await actor.incrementSync(by: 5)
        
        let value: Int = await actor.value
        
        XCTAssertEqual(value, 5)
    }
    
    
    
    @MainActor
    func testMainActorWithClosureAsync() async
    {
        let box = Box(10)
        
        await mainActorWithClosure(box)
        {
            /// Force suspension so the closure exercises its isolation.
            await Task.yield()
            
            $0.value += 1
        }
        
        XCTAssertEqual(box.value, 11)
    }
    
    
    
    @MainActor
    func testMainActorWithClosureSync()
    {
        let box = Box(10)
        
        mainActorWithClosure(box)
        {
            $0.value += 1
        }
        
        XCTAssertEqual(box.value, 11)
    }
    
    
    
    func testIsolatedWithClosureAsync() async
    {
        let actor = TestActor()
        
        await actor.incrementWithClosureAsync()
        
        let value: Int = await actor.value
        
        XCTAssertEqual(value, 5)
    }
    
    
    
    func testIsolatedWithClosureSync() async
    {
        let actor = TestActor()
        
        await actor.incrementWithClosureSync()
        
        let value: Int = await actor.value
        
        XCTAssertEqual(value, 5)
    }
}



// MARK: - Support


@Reasync
private func acceptSending(
    _ box: sending Box
) async
{
    box.value += 1
}



@Reasync
private func produceSending(
    _ value: Int
) async -> sending Box
{
    return Box(value)
}



@Reasync
private func transformSending(
    _ box: sending Box
) async -> sending Box
{
    box.value *= 2
    
    return box
}



@Reasync
@MainActor
private func mainActorIncrement(
    _ box: Box
) async
{
    box.value += 1
}



private actor TestActor
{
    var value: Int = 0
    
    func incrementSync(
        by amount: Int
    )
    {
        isolatedIncrement(
            on:     self,
            by:     amount
        )
    }
    
    func incrementWithClosureAsync() async
    {
        await isolatedWithClosure(on: self)
        {
            /// Force suspension so the closure exercises its isolation.
            await Task.yield()
            
            $0.value += 5
        }
    }
    
    func incrementWithClosureSync()
    {
        isolatedWithClosure(on: self)
        {
            $0.value += 5
        }
    }
}



@Reasync
private func isolatedIncrement(
    on  actor   : isolated TestActor,
    by  amount  : Int
) async
{
    actor.value += amount
}



@Reasync
private func isolatedWithClosure(
    on  actor   : isolated TestActor,
    _   body    : (isolated TestActor) async -> Void
) async
{
    await body(actor)
}



@Reasync
@MainActor
private func mainActorWithClosure(
    _ box   : Box,
    apply   : (Box) async -> Void
) async
{
    await apply(box)
}
