//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Marek Zvara on 12/12/2022.
//

import Foundation

public enum FeedLoaderResult<Error: Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}

extension FeedLoaderResult: Equatable where Error: Equatable {}

protocol FeedLoader {
    associatedtype Error: Swift.Error
    func load(completion: @escaping (FeedLoaderResult<Error>) -> Void)
}

