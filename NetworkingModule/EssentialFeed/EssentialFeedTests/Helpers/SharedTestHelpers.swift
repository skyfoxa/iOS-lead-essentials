//
//  SharedTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Marek Zvara on 31/01/2023.
//

import Foundation

func anyNSError() -> NSError {
    NSError(domain: "any error", code: 1)
}

func anyURL() -> URL {
    URL(string: "https://any-url.com")!
}
