//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Marek Zvara on 12/12/2022.
//

import Foundation

public enum FeedLoaderResult {
    case success([FeedImage])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (FeedLoaderResult) -> Void)
}

