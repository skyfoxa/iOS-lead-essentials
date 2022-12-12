//
//  FeedLoader.swift
//  
//
//  Created by Marek Zvara on 06/12/2022.
//

import Foundation

enum FeedLoaderResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (FeedLoaderResult) -> Void)
}
