//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Marek Zvara on 12/12/2022.
//

import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() throws {
        // Given
        let (_, client) = _makeSUT()
                
        // Assert
        XCTAssert(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() throws {
        // Given
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = _makeSUT(url: url)
              
        // When
        sut.load { _ in }
        
        // Assert
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_requestsDataFromURLTwice() throws {
        // Given
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = _makeSUT(url: url)
              
        // When
        sut.load { _ in }
        sut.load { _ in }
        
        // Assert
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        // Given
        let (sut, client) = _makeSUT()
              
        // When
        expect(sut, toCompleteWithResult: .failure(.connectivity)) {
            let clientError = NSError(domain: "test", code: 0)
            client.complete(with: clientError, at: 0)
        }
    }
    
    func test_load_deliversErrorOnNon200HTTPResponse() {
        // Given
        let (sut, client) = _makeSUT()
              
        // When
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, code in
            expect(sut, toCompleteWithResult: .failure(.invalidData)) {
                client.complete(withStatusCode: code, at: index)
            }
        }
        
    }
    
    func test_load_deliversErrorOn200HTTPResponseInvalidJSON() {
        // Given
        let (sut, client) = _makeSUT()
              
        // When
        expect(sut, toCompleteWithResult: .failure(.invalidData)) {
            let invalidJSON = "Invalid json".data(using: .utf8)!
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
    
    func test_load_deliversNoItemsOn200HTTPResponseWithEmptyJSONList() {
        // Given
        let (sut, client) = _makeSUT()

        // When
        expect(sut, toCompleteWithResult: .success([])) {
            let emptyJSON = "{\"items\": []}".data(using: .utf8)!
            client.complete(withStatusCode: 200, data: emptyJSON)
        }
    }
    
    func test_load_deliversItemsOn200HTTPResponseWithJSONItems() {
        // Given
        let (sut, client) = _makeSUT()
        
        let item1 = FeedItem(id: .init(),
                             imageURL: URL(string: "https://a-url.com")!)
        let item1JSON = [
            "id" : item1.id.uuidString,
            "image" : item1.imageURL.absoluteString
        ]
        
        let item2 = FeedItem(id: .init(),
                             description: "a description",
                             location: "a location",
                             imageURL: URL(string: "https://a-url.com")!)
        let item2JSON = [
            "id" : item2.id.uuidString,
            "description" : item2.description,
            "location" : item2.location,
            "image" : item2.imageURL.absoluteString
        ]
        
        let itemsJSON = [
            "items" : [item1JSON, item2JSON]
        ]
        
        expect(sut, toCompleteWithResult: .success([item1, item2])) {
            let json = try! JSONSerialization.data(withJSONObject: itemsJSON)
            client.complete(withStatusCode: 200, data: json)
        }
    }
}

private extension RemoteFeedLoaderTests {
    func _makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    func expect(_ sut: RemoteFeedLoader, toCompleteWithResult result: RemoteFeedLoader.Result, action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var capturedResult: [RemoteFeedLoader.Result] = []
        sut.load { capturedResult.append($0) }
        action()
        XCTAssertEqual(capturedResult, [result], file: file, line: line)
    }
    
    class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] {
            messages.map(\.url)
        }
        var messages: [(url: URL, completion: (HTTPClientResult) -> ())] = []
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> ()) {
            self.messages.append((url, completion))
        }
        
        func complete(with error: Error, at index: Int) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, data: Data = Data(), at index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index],
                                           statusCode: code,
                                           httpVersion: nil,
                                           headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }

}
