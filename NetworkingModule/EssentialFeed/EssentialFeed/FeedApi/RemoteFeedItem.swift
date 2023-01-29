//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Marek Zvara on 29/01/2023.
//

import Foundation

internal struct RemoteFeedItem: Decodable {
    internal let id: UUID
    internal let description: String?
    internal let location: String?
    internal let image: URL
}
