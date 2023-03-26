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
        let feed: [CodableFeedImage]
        let timestamp: Date
        
        var localFeed: [LocalFeedImage] {
            feed.map {
                $0.local
            }
        }
    }
    
    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: URL
        
        init(_ image: LocalFeedImage) {
            self.id = image.id
            self.description = image.description
            self.location = image.location
            self.url = image.url
        }
        
        var local: LocalFeedImage {
            .init(id: id, description: description, location: location, url: url)
        }
        
    }
    
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        let decoder = JSONDecoder()
        
        guard let data = try? Data(contentsOf: storeURL) else {
            return completion(.empty)
        }
        let cache = try! decoder.decode(Cache.self, from: data)
        completion(.found(feed: cache.localFeed, timestamp: cache.timestamp))
    }
    
    func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let encoder = JSONEncoder()
        let cache = Cache(feed: feed.map(CodableFeedImage.init), timestamp: timestamp)
        let encoded = try! encoder.encode(cache)
        try! encoded.write(to: storeURL)
        completion(nil)
    }
}

final class CodableFeedStoreTests: XCTestCase {
   
    override func setUp() {
        super.setUp()
        
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        
        undoStoreSideEffects()
    }
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieve: .empty)
        
    }

    func test_retrieve_hasNoSideEffectOnEmptyCache() {
       let sut = makeSUT()
        
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
        let sut = makeSUT()
        let feed = uniqueImageFeed().locals
        let timestamp = Date()
         
        let exp = expectation(description: "Wait for cache retireval")
        sut.insert(feed, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
            exp.fulfill()
        }

        waitForExpectations(timeout: 1.0)
        
        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp))

    }
    
    func test_retrieveAfterInsertingToEmptyCache_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().locals
        let timestamp = Date()
         
         let exp = expectation(description: "Wait for cache retireval")
         sut.insert(feed, timestamp: timestamp) { insertionError in
             XCTAssertNil(insertionError, "Expected feed to be inserted successfully")
             sut.retrieve { firstResult in
                 sut.retrieve { secondsResult in
                     switch (firstResult, secondsResult) {
                     case let (.found(firstFoundFeed, firstFoundTimestamp), .found(secondFoundFeed, secondsFoundTimestamp)):
                         XCTAssertEqual(firstFoundFeed, feed)
                         XCTAssertEqual(firstFoundTimestamp, timestamp)
                         
                         XCTAssertEqual(secondFoundFeed, feed)
                         XCTAssertEqual(secondsFoundTimestamp, timestamp)
                     default:
                         XCTFail("Expected retrieving twice from non empty cache to deliver same found result with feed \(feed) and timestamp \(timestamp), got first result \(firstResult) and second result \(secondsResult) instead")
                     }
                     
                     exp.fulfill()
                 }
             }
         }
         
         waitForExpectations(timeout: 1.0)
    }
}

private extension CodableFeedStoreTests {
    
    func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let sut = CodableFeedStore(storeURL: testSpecificStoreURL())
        traceForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func expect(_ sut: CodableFeedStore, toRetrieve: RetrieveCacheFeedResult) {
        let exp = expectation(description: "Cache retrieved")
        sut.retrieve { retrieveResult in
            XCTAssertEqual(retrieveResult, toRetrieve)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testSpecificStoreURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("\(type(of: self)).store")
    }
    
    func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}

extension RetrieveCacheFeedResult: Equatable {
    public static func == (lhs: EssentialFeed.RetrieveCacheFeedResult, rhs: EssentialFeed.RetrieveCacheFeedResult) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty):
            return true
        case let (.found(lhsFeed, lhsTimestamp), .found(rhsFeed, rhsTimestamp)):
            return lhsFeed == rhsFeed && lhsTimestamp == rhsTimestamp
        case let (.failure(lhsError), .failure(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
    
    
}
