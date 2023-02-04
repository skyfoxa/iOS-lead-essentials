//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Marek Zvara on 04/02/2023.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    
    private struct Cache: Codable {
        let feed: [LocalFeedImage]
        let timestamp: Date
    }
    
    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        let decoder = JSONDecoder()
        
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.feed, timestamp: cache.timestamp))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let encoded = try! encoder.encode(Cache(feed: feed, timestamp: timestamp))
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

final class CodableFeedStoreTests: XCTestCase {
   
    override func setUp() {
        super.setUp()
        
        try? FileManager.default.removeItem(at: testContextCacheURL())
    }
    
    override func tearDown() {
        super.tearDown()
        
        try? FileManager.default.removeItem(at: testContextCacheURL())
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
       let sut = CodableFeedStore()
        
        let exp = expectation(description: "Wait for cache retrieval")
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            case .found, .failure:
                XCTFail("Expected empty result, got \(result) instead")
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
    }

    func test_retrieve_hasNoSideEffectOnEmptyCache() {
       let sut = CodableFeedStore()
        
        let exp = expectation(description: "Wait for cache retireval")
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("Expected retrieving twice from empty cache to deliver same empty result, got \(firstResult) and \(secondResult) instead")
                }
                
                exp.fulfill()
            }
        }
        
        waitForExpectations(timeout: 1.0)
    }
    
    func test_retrieveAfterInsertingToEmptyCache_deliversInsertedValues() {
        let sut = CodableFeedStore()
        let feed = uniqueImageFeed().locals
        let timestamp = Date()
         
         let exp = expectation(description: "Wait for cache retireval")
         sut.insert(feed, timestamp: timestamp) { insertionError in
             XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
             sut.retrieve { retrieveError in
                 switch retrieveError {
                 case let .found(retrievedFeed, retrievedTimestamp):
                     XCTAssertEqual(retrievedFeed, feed)
                     XCTAssertEqual(timestamp, retrievedTimestamp)
                 default:
                     XCTFail("Expected retrieving cache, got \(retrieveError) instead")
                 }
                 
                 exp.fulfill()
             }
         }
         
         waitForExpectations(timeout: 1.0)
    }
}

private extension CodableFeedStoreTests {
    
    func testContextCacheURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("image-feed.store")
    }
}
