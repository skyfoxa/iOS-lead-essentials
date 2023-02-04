//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Marek Zvara on 04/02/2023.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
        completion(.empty)
    }
}

final class CodableFeedStoreTests: XCTestCase {
   

    func test_retrieve_deliversEmptyOnEmptyCache() {
       let sut = CodableFeedStore()
        
        let exp = expectation(description: "Wait for cache retireval")
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

    

}