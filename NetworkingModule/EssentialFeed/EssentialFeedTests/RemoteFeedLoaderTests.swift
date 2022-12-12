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
        sut.load()
        
        // Assert
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_load_requestsDataFromURLTwice() throws {
        // Given
        let url = URL(string: "https://a-url.com")!
        let (sut, client) = _makeSUT(url: url)
              
        // When
        sut.load()
        sut.load()
        
        // Assert
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        // Given
        let (sut, client) = _makeSUT()
              
        // When
        var capturedError: [RemoteFeedLoader.Error] = []
        sut.load { capturedError.append($0) }
        let clientError = NSError(domain: "test", code: 0)
        client.complete(with: clientError, at: 0)
        
        // Assert
        XCTAssertEqual(capturedError, [.connectivity])
    }
}

private extension RemoteFeedLoaderTests {
    func _makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPCLientSpy) {
        let client = HTTPCLientSpy()
        let sut = RemoteFeedLoader(client: client, url: url)
        return (sut, client)
    }
    
    class HTTPCLientSpy: HTTPClient {
        var requestedURLs: [URL] = []
        var completions: [(Error) -> ()] = []
        
        func get(from url: URL, completion: @escaping (Error) -> ()) {
            self.completions.append(completion)
            self.requestedURLs.append(url)
        }
        
        func complete(with error: Error, at index: Int) {
            completions[index](error)
        }
    }

}
