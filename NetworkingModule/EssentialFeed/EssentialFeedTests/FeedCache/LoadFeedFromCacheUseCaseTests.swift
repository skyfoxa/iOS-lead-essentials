//
//  LocalFeedFromCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Marek Zvara on 29/01/2023.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {


    func test_init() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }

}

private extension LoadFeedFromCacheUseCaseTests {
    func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        traceForMemoryLeaks(sut, file: file, line: line)
        traceForMemoryLeaks(store, file: file, line: line)
        return (sut, store)
    }
}
