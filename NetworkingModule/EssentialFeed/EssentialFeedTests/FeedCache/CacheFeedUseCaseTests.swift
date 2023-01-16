//
//  CacheFeedUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Marek Zvara on 16/01/2023.
//

import XCTest

class LocalFeedLoader {
    
    init(store: FeedStore) {}
}

class FeedStore {
    var deleteCachedFeedCallCount = 0
}

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUponCreation() {
        let store = FeedStore()
        let _ = LocalFeedLoader(store: store)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }

}
