//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Marek Zvara on 12/12/2022.
//

import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public typealias Result = FeedLoaderResult
    
    public init(client: HTTPClient, url: URL) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void ) {
        client.get(from: url) { [weak self] result in
            guard let _ = self else { return }
            
            switch result {
            case let .success(data, response):
                completion(RemoteFeedLoader.map(data, response))
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
    
    private static func map(_ data: Data, _ response: HTTPURLResponse) -> Result {
        do {
            let items = try FeedItemsMapper.map(data, from: response)
            return .success(items.toModels())
        } catch {
            return .failure(error)
        }
    }
}

private extension [RemoteFeedItem] {
    func toModels() -> [FeedImage] {
        map { .init(id: $0.id,
                    description: $0.description,
                    location: $0.location,
                    url: $0.image)
        }
    }
}

