//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Marek Zvara on 23/12/2022.
//

import XCTest
import EssentialFeed


class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedValuesRepresentation: Error {}
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { _, _, error in
            if let error = error {
                completion(.failure(error))
            }
            else {
                completion(.failure(UnexpectedValuesRepresentation()))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    override class func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override class func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performsGETRequestWithUrl() {
        let url = anyURL()
        let exp = expectation(description: "Wait for request")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        makeSUT().get(from: url, completion: {_ in})
        
        waitForExpectations(timeout: 0.1)
    }
    
    func test_getFromURL_failsOnRequestError() {
        let error = NSError(domain: "any error", code: 1)
        
        let receivedError = resultError(for: nil, response: nil, error: error)
        
        XCTAssertEqual(error.domain, (receivedError as? NSError)?.domain)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        let nonHTTPResponse = URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let httpResponse = HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)
        let anyData = "Any data".data(using: .utf8)!
        let anyError = NSError(domain: "any error", code: 1)
        XCTAssertNotNil(resultError(for: nil, response: nil, error: nil))
        XCTAssertNotNil(resultError(for: nil, response: nonHTTPResponse, error: nil))
        XCTAssertNotNil(resultError(for: nil, response: httpResponse, error: nil))
        XCTAssertNotNil(resultError(for: anyData, response: nil, error: nil))
        XCTAssertNotNil(resultError(for: anyData, response: nil, error: anyError))
        XCTAssertNotNil(resultError(for: nil, response: nonHTTPResponse, error: anyError))
        XCTAssertNotNil(resultError(for: nil, response: httpResponse, error: anyError))
        XCTAssertNotNil(resultError(for: anyData, response: nonHTTPResponse, error: anyError))
        XCTAssertNotNil(resultError(for: anyData, response: httpResponse, error: anyError))
        XCTAssertNotNil(resultError(for: anyData, response: nonHTTPResponse, error: nil))
    }
}

// MARK: - Helpers
private extension URLSessionHTTPClientTests {
    func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        traceForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func anyURL() -> URL {
        URL(string: "https://any-url.com")!
    }
    
    
    func resultError(for data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        URLProtocolStub.stub(data: data, response: response, error: error)
                
        let exp = expectation(description: "Wait for completion")
        var responseError: Error?
        makeSUT(file: file, line: line).get(from: anyURL()) { result in
            switch result {
            case let .failure(receivedError):
                responseError = receivedError
            default:
                XCTFail("Expected failure but got \(result)")
            }
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 0.1)
        
        return responseError
    }
}

private extension URLSessionHTTPClientTests {
    class URLProtocolStub: URLProtocol {
        
        private static var stub: Stub? = nil
        private static var requestObserver: ((URLRequest) -> ())?
        
        private struct Stub {
            let error: Error?
            let data: Data?
            let response: URLResponse?
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> ()) {
            requestObserver = observer
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(error: error, data: data, response: response)
        }
        
        static func startInterceptingRequests() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func stopInterceptingRequests() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
            requestObserver = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            requestObserver?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let stub = Self.stub
            else {
                return
            }
            
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
            
        }
        
        override func stopLoading() {
            
        }
    }
}
