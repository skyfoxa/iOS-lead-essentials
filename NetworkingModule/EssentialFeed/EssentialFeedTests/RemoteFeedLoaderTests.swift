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
        expect(sut, toCompleteWithError: .connectivity) {
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
            expect(sut, toCompleteWithError: .invalidData) {
                client.complete(withStatusCode: code, at: index)
            }
        }
        
    }
    
    func test_load_deliversErrorOn200HTTPResponseInvalidJSON() {
        // Given
        let (sut, client) = _makeSUT()
              
        // When
        expect(sut, toCompleteWithError: .invalidData) {
            let invalidJSON = "Invalid json".data(using: .utf8)!
            client.complete(withStatusCode: 200, data: invalidJSON)
        }
    }
}

private extension RemoteFeedLoaderTests {
    func _makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    func expect(_ sut: RemoteFeedLoader, toCompleteWithError error: RemoteFeedLoader.Error, action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var capturedError: [RemoteFeedLoader.Error] = []
        sut.load { capturedError.append($0) }
        action()
        XCTAssertEqual(capturedError, [error], file: file, line: line)
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
