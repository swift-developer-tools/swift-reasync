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



internal final class ReasyncMemberMacroIntegrationTests: XCTestCase
{
    // MARK: - Struct
    
    func testAsyncOnlyDoubleStructAsync() async
    {
        let result: Int = await AsyncOnlyDoubleStruct().double(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testAsyncOnlyDoubleStructSync()
    {
        let result: Int = AsyncOnlyDoubleStruct().double(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testSyncOnlyDoubleStructSync()
    {
        let result: Int = SyncOnlyDoubleStruct().double(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testMixedStructAsyncDoubleAsync() async
    {
        let result: Int = await MixedStruct().asyncDouble(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testMixedStructAsyncDoubleSync()
    {
        let result: Int = MixedStruct().asyncDouble(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testMixedStructSyncIncrementSync()
    {
        let result: Int = MixedStruct().syncIncrement(5)
        
        XCTAssertEqual(result, 6)
    }
    
    
    
    func testMixedStructReasyncDecrementAsync() async
    {
        let result: Int = await MixedStruct().reasyncDecrement(5)
        
        XCTAssertEqual(result, 4)
    }
    
    
    
    func testMixedStructReasyncDecrementSync()
    {
        let result: Int = MixedStruct().reasyncDecrement(5)
        
        XCTAssertEqual(result, 4)
    }
    
    
    
    // MARK: - Class
    
    func testAsyncOnlyDoubleClassAsync() async
    {
        let result: Int = await AsyncOnlyDoubleClass().double(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testAsyncOnlyDoubleClassSync()
    {
        let result: Int = AsyncOnlyDoubleClass().double(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    // MARK: - Enum
    
    func testAsyncOnlyDoubleEnumAsync() async
    {
        let result: Int = await AsyncOnlyDoubleEnum.value(5).double()
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testAsyncOnlyDoubleEnumSync()
    {
        let result: Int = AsyncOnlyDoubleEnum.value(5).double()
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    // MARK: - Actor
    
    func testAsyncOnlyDoubleActorAsync() async
    {
        let result: Int = await AsyncOnlyDoubleActor().double(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testAsyncOnlyDoubleActorSync()
    {
        let result: Int = AsyncOnlyDoubleActor().double(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    // MARK: - Extension
    
    func testAsyncOnlyExtendedDoubleStructAsync() async
    {
        let result: Int = await AsyncOnlyExtendedDoubleStruct().double(5)
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testAsyncOnlyExtendedDoubleStructSync()
    {
        let result: Int = AsyncOnlyExtendedDoubleStruct().double(5)
        
        XCTAssertEqual(result, 10)
    }
}



// MARK: - Support

@ReasyncMembers
private struct AsyncOnlyDoubleStruct
{
    func double(
        _ value: Int
    ) async -> Int
    {
        return value * 2
    }
}



@ReasyncMembers
private struct SyncOnlyDoubleStruct
{
    func double(
        _ value: Int
    ) -> Int
    {
        return value * 2
    }
}



@ReasyncMembers
private struct MixedStruct
{
    func asyncDouble(
        _ value: Int
    ) async -> Int
    {
        return value * 2
    }
    
    func syncIncrement(
        _ value: Int
    ) -> Int
    {
        return value + 1
    }
    
    @Reasync
    func reasyncDecrement(
        _ value: Int
    ) async -> Int
    {
        return value - 1
    }
}



@ReasyncMembers
private final class AsyncOnlyDoubleClass
{
    func double(
        _ value: Int
    ) async -> Int
    {
        return value * 2
    }
}



@ReasyncMembers
private enum AsyncOnlyDoubleEnum
{
    case value(Int)
    
    func double() async -> Int
    {
        switch self
        {
            case let .value(n): return n * 2
        }
    }
}



@ReasyncMembers
private actor AsyncOnlyDoubleActor
{
    nonisolated func double(
        _ value: Int
    ) async -> Int
    {
        return value * 2
    }
}



private struct AsyncOnlyExtendedDoubleStruct { }

@ReasyncMembers
extension AsyncOnlyExtendedDoubleStruct
{
    func double(
        _ value: Int
    ) async -> Int
    {
        return value * 2
    }
}
