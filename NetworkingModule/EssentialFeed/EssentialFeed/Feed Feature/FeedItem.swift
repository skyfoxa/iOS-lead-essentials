//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Marek Zvara on 12/12/2022.
//

import Foundation

public struct FeedItem {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: URL
}
