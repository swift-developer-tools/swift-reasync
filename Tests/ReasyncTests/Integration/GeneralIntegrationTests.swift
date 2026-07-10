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



internal final class GeneralIntegrationTests: XCTestCase
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
    
    
    
    func testComputedPropertyAsync() async
    {
        let result: Int = await computedProperty()
        
        XCTAssertEqual(result, 0)
    }
    
    
    
    func testComputedPropertySync()
    {
        let result: Int = computedProperty()
        
        XCTAssertEqual(result, 0)
    }
    
    
    
    func testDoublerProtocolAsync() async
    {
        let doubler: any DoublerProtocol = DoublerStruct()
        
        let result: Int = await doubler.double(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testDoublerProtocolSync()
    {
        let doubler: any DoublerProtocol = DoublerStruct()
        
        let result: Int = doubler.double(5)
        
        XCTAssertEqual(result, 10)
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
private func quadruple(
    _ value: Int
) async -> Int
{
    let result: Int = await double(value)
    
    return result * 2
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
private func computedProperty() async -> Int
{
    var x: Int
    {
        get async
        {
            return 0
        }
    }
    
    return await x
}



private protocol DoublerProtocol { }

extension DoublerProtocol
{
    @Reasync
    func double(
        _ value: Int
    ) async -> Int
    {
        return value * 2
    }
}

private struct DoublerStruct: DoublerProtocol { }
