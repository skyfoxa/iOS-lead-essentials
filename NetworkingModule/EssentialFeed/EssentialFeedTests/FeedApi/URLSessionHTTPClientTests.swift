//
//  URLSessionHTTPClientTests.swift
//  EssentialFeedTests
//
//  Created by Marek Zvara on 23/12/2022.
//

import XCTest
import EssentialFeed


class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedValuesRepresentation: Error {}
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
            }
            else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
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
        let data = Data()
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
        traceForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    func anyURL() -> URL {
        URL(string: "https://any-url.com")!
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
    
    func anyNSError() -> NSError {
        NSError(domain: "any error", code: 1)
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
