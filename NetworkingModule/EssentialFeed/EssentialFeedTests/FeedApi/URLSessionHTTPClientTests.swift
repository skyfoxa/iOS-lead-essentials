//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Marek Zvara on 23/12/2022.
//

import XCTest
import EssentialFeed

final class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
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
        let error = anyNSError()
        
        let receivedError = resultError(for: nil, response: nil, error: error)
        
        XCTAssertEqual(error.domain, (receivedError as? NSError)?.domain)
    }
    
    func test_getFromURL_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultError(for: nil, response: nil, error: nil))
        XCTAssertNotNil(resultError(for: nil, response: nonHTTPResponse(), error: nil))
        XCTAssertNotNil(resultError(for: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultError(for: anyData(), response: nil, error: anyNSError()))
        XCTAssertNotNil(resultError(for: nil, response: nonHTTPResponse(), error: anyNSError()))
        XCTAssertNotNil(resultError(for: nil, response: httpResponse(), error: anyNSError()))
        XCTAssertNotNil(resultError(for: anyData(), response: nonHTTPResponse(), error: anyNSError()))
        XCTAssertNotNil(resultError(for: anyData(), response: httpResponse(), error: anyNSError()))
        XCTAssertNotNil(resultError(for: anyData(), response: nonHTTPResponse(), error: nil))
    }
    
    func test_getFromURL_suceedsOnHTTPUrlResponseWithData() {
        let data = anyData()
        let response = httpResponse()
        let receivedValues = resultValues(for: data, response: response, error: nil)

        XCTAssertEqual(receivedValues?.data, data)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
    
    func test_getFromURL_suceedsWithEmptyDataOnHTTPUrlResponseWithNilData() {
        let response = httpResponse()
        let receivedValues = resultValues(for: nil, response: response, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(receivedValues?.data, emptyData)
        XCTAssertEqual(receivedValues?.response.url, response.url)
        XCTAssertEqual(receivedValues?.response.statusCode, response.statusCode)
    }
}

// MARK: - Helpers
private extension URLSessionHTTPClientTests {
    func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
        let sut = URLSessionHTTPClient()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func nonHTTPResponse() -> URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    func httpResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    func anyData() -> Data {
        "Any data".data(using: .utf8)!
    }
    
    func resultError(for data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> Error? {
        let result = resultFor(data: data, response: response, error: error)
                
        var responseError: Error?
        switch result {
        case let .failure(receivedError):
            responseError = receivedError
        default:
            XCTFail("Expected failure but got \(result)")
        }
        
        return responseError
    }
    
    func resultValues(for data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error)
                
        var responseValues: (data: Data, response: HTTPURLResponse)?
        
        switch result {
        case let .failure(receivedError):
            XCTFail("Expected success but got \(receivedError)")
        case let .success(data, response):
            responseValues = (data, response)
            
        }
        
        return responseValues
    }
    
    func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #filePath, line: UInt = #line) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
                
        let sut = makeSUT(file: file, line: line)
        let exp = expectation(description: "Wait for completion")
        var responseResult: HTTPClientResult!
        sut.get(from: anyURL()) { result in
            responseResult = result
            
            exp.fulfill()
        }
        
        waitForExpectations(timeout: 1.0)
        
        return responseResult
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
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            if let requestObserver = URLProtocolStub.requestObserver {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
            
        }
        
        override func stopLoading() {
            
        }
    }
}
