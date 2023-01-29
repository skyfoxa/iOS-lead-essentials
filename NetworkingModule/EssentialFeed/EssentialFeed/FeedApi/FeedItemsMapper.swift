//
//  FeedItemsMapper.swift
//  EssentialFeed
//
//  Created by Marek Zvara on 23/12/2022.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}

final class FeedItemsMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }

    
    
    static func map(_ data: Data, from response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard
            response.statusCode == 200,
            let root = try? JSONDecoder().decode(Root.self, from: data)
        else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        return root.items
    }
}
