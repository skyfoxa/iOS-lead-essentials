//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Marek Zvara on 26/03/2023.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {

    func assertThatRetrieveDeliversEmptyOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        expect(sut, toRetrieveTwice: .empty, file: file, line: line)
    }

    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = uniqueImageFeed().locals
        let timestamp = Date()

        insert(sut, feed, timestamp)

        expect(sut, toRetrieve: .found(feed: feed, timestamp: timestamp), file: file, line: line)
    }

    func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let feed = uniqueImageFeed().locals
        let timestamp = Date()

        insert(sut, feed, timestamp)

        expect(sut, toRetrieveTwice: .found(feed: feed, timestamp: timestamp), file: file, line: line)
    }

    func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let insertionError = insert(sut, uniqueImageFeed().locals, Date())

        XCTAssertNil(insertionError, "Expected to insert cache successfully", file: file, line: line)
    }

    func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert(sut, uniqueImageFeed().locals, Date())

        let insertionError = insert(sut, uniqueImageFeed().locals, Date())

        XCTAssertNil(insertionError, "Expected to override cache successfully", file: file, line: line)
    }

    func assertThatInsertOverridesPreviouslyInsertedCacheValues(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert(sut, uniqueImageFeed().locals, Date())

        let latestFeed = uniqueImageFeed().locals
        let latestTimestamp = Date()
        insert(sut, latestFeed, latestTimestamp)

        expect(sut, toRetrieve: .found(feed: latestFeed, timestamp: latestTimestamp), file: file, line: line)
    }

    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed", file: file, line: line)
    }

    func assertThatDeleteHasNoSideEffectsOnEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert(sut, uniqueImageFeed().locals, Date())

        let deletionError = deleteCache(from: sut)

        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed", file: file, line: line)
    }

    func assertThatDeleteEmptiesPreviouslyInsertedCache(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert(sut, uniqueImageFeed().locals, Date())

        deleteCache(from: sut)

        expect(sut, toRetrieve: .empty, file: file, line: line)
    }

    func assertThatSideEffectsRunSerially(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        var completedOperationsInOrder = [XCTestExpectation]()

        let op1 = expectation(description: "Operation 1")
        sut.insert(uniqueImageFeed().locals, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op1)
            op1.fulfill()
        }

        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            completedOperationsInOrder.append(op2)
            op2.fulfill()
        }

        let op3 = expectation(description: "Operation 3")
        sut.insert(uniqueImageFeed().locals, timestamp: Date()) { _ in
            completedOperationsInOrder.append(op3)
            op3.fulfill()
        }

        waitForExpectations(timeout: 5.0)

        XCTAssertEqual(completedOperationsInOrder, [op1, op2, op3], "Expected side-effects to run serially but operations finished in the wrong order", file: file, line: line)
    }

}

extension FeedStoreSpecs where Self: XCTestCase {
    func expect(_ sut: FeedStore, toRetrieve: RetrieveCacheFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "Cache retrieved")
        sut.retrieve { retrieveResult in
            XCTAssertEqual(retrieveResult, toRetrieve)
            exp.fulfill()
        }
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func expect(_ sut: FeedStore, toRetrieveTwice: RetrieveCacheFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: toRetrieveTwice, file: file, line: line)
        expect(sut, toRetrieve: toRetrieveTwice, file: file, line: line)
    }
    
    @discardableResult
    func insert(_ sut: FeedStore, _ feed: [LocalFeedImage], _ timestamp: Date) -> Error? {
        let exp = expectation(description: "Wait for cache insertion")
        var insertionError: Error?
        sut.insert(feed, timestamp: timestamp) { receivedInsertionError in
            insertionError = receivedInsertionError
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        return insertionError
    }
    
    @discardableResult
    func deleteCache(from sut: FeedStore) -> Error? {
        let exp = expectation(description: "Wait for cache deletion")
        var deletionError: Error?
        sut.deleteCachedFeed { receivedDeletionError in
            deletionError = receivedDeletionError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5.0)
        return deletionError
    }
}

extension RetrieveCacheFeedResult: Equatable {
    public static func == (lhs: EssentialFeed.RetrieveCacheFeedResult, rhs: EssentialFeed.RetrieveCacheFeedResult) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty),
            (.failure, .failure):
            return true
        case let (.found(lhsFeed, lhsTimestamp), .found(rhsFeed, rhsTimestamp)):
            return lhsFeed == rhsFeed && lhsTimestamp == rhsTimestamp
        default:
            return false
        }
    }    
}
