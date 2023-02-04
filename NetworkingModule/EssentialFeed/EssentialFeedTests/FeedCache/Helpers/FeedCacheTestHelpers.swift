//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Marek Zvara on 31/01/2023.
//

import Foundation
import EssentialFeed


func uniqueImageFeed() -> (models: [FeedImage], locals: [LocalFeedImage]) {
    let items = [uniqueImage(), uniqueImage()]
    let localItems = items.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    return (items, localItems)
}

func uniqueImage() -> FeedImage {
    .init(id: .init(), description: "any", location: "any", url: anyURL())
}

extension Date {
    
    func minusFeedCacheMaxAge() -> Date {
        adding(day: -feedCacheMaxAgeInDays)
    }
    
    private var feedCacheMaxAgeInDays: Int {
        7
    }
    
    private func adding(day: Int) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        
        return calendar.date(byAdding: .day, value: day, to: self)!
    }
    
    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
