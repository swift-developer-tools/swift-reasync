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



internal final class ErrorHandlingIntegrationTests: XCTestCase
{
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
    
    
    
    func testIncrementThrowAsync() async
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
    
    
    
    func testIncrementThrowSync()
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
    
    
    
    func testThrowsTestErrorAsync() async
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
    
    
    
    func testThrowsTestErrorSync()
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
    
    
    
    func testTryTransformAsync() async throws
    {
        let result: Int = try await tryTransform(
            5,
            by: { value async throws(TestError) in value * 2 }
        )
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testTryTransformSync() throws
    {
        let result: Int = try tryTransform(
            5,
            by: { value throws(TestError) in value * 2 }
        )
        
        XCTAssertEqual(result, 10)
    }
    
    
    
    func testTryTransformAsyncThrows() async
    {
        do
        {
            _ = try await tryTransform(
                5,
                by: { _ async throws(TestError) in throw TestError() }
            )
            
            XCTFail("Expected thrown error")
        }
        catch
        {
            /// Do nothing.
        }
    }
    
    
    
    func testTryTransformSyncThrows()
    {
        do
        {
            _ = try tryTransform(
                5,
                by: { _ throws(TestError) in throw TestError() }
            )
            
            XCTFail("Expected thrown error")
        }
        catch
        {
            /// Do nothing.
        }
    }
}



// MARK: - Support

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



internal struct TestError: Error { }



@Reasync
@discardableResult
private func throwsTestError() async throws(TestError) -> Int
{
    throw TestError()
}



@Reasync
private func tryTransform(
    _   value       : Int,
    by  transform   : (Int) async throws(TestError) -> Int
) async throws(TestError) -> Int
{
    return try await transform(value)
}
