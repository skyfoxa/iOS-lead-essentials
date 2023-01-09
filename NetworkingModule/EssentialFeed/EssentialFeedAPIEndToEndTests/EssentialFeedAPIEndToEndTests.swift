//
//  EssentialFeedAPIEndToEndTests.swift
//  EssentialFeedAPIEndToEndTests
//
//  Created by Marek Zvara on 02/01/2023.
//

import XCTest
import EssentialFeed

final class EssentialFeedAPIEndToEndTests: XCTestCase {

    func test_endToEndTestServerGETFeedResult_matchesFixedTestAccountData() throws {
        switch getFeedResult() {
        case let .success(items):
            XCTAssertEqual(items.count, 8, "Expected 8 testing items in the feed")
            
            items.enumerated().forEach { (index, item) in
                XCTAssertEqual(item, expectedItem(at: index), "Unexpected item values at index \(index)")
            }
        case let .failure(error):
            XCTFail("Expected successfull state but got \(error)")
        default:
            XCTFail("Expected successfull feed result, got nil result instead")
        }
    }
}

private extension EssentialFeedAPIEndToEndTests {
    
    func getFeedResult(file: StaticString = #filePath, line: UInt = #line) -> FeedLoaderResult? {
        // Given
        let testServerURL = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
        let client = URLSessionHTTPClient(session: .init(configuration: .ephemeral))
        let loader = RemoteFeedLoader(client: client, url: testServerURL)
        traceForMemoryLeaks(client, file: file, line: line)
        traceForMemoryLeaks(loader, file: file, line: line)
        
        // When
        let exp = expectation(description: "When feed loaded")
        
        var receivedResult: FeedLoaderResult?
        loader.load { result in
            receivedResult = result
            exp.fulfill()
        }
        
        // Assert
        waitForExpectations(timeout: 5.0)
        
        return receivedResult
    }
    
    func expectedItem(at index: Int) -> FeedItem {
        FeedItem(id: expectedID(at: index),
                 description: expectedDescription(at: index),
                 location: expectedLoaction(at: index),
                 imageURL: expectedURL(at: index))
    }
    
    func expectedID(at index: Int) -> UUID {
        return UUID(uuidString: [
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "BA298A85-6275-48D3-8315-9C8F7C1CD109",
            "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
            "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
            "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
            "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
            "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
            "F79BD7F8-063F-46E2-8147-A67635C3BB01"
        ][index])!
    }
    
    func expectedDescription(at index: Int) -> String? {
        return [
            "Description 1",
            nil,
            "Description 3",
            nil,
            "Description 5",
            "Description 6",
            "Description 7",
            "Description 8"
        ][index]
    }
    
    func expectedLoaction(at index: Int) -> String? {
        return [
            "Location 1",
            "Location 2",
            nil,
            nil,
            "Location 5",
            "Location 6",
            "Location 7",
            "Location 8"
        ][index]
    }
    
    func expectedURL(at index: Int) -> URL {
        return URL(string: "https://url-\(index+1).com")!
    }
}
