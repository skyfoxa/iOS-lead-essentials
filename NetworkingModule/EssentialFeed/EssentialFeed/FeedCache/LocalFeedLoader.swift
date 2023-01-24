//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Marek Zvara on 18/01/2023.
//

import Foundation

public final class LocalFeedLoader {
    
    private let store: FeedStore
    private let currentDate: () -> Date
    
    public typealias SaveResult = Error?
    
    public init(store: FeedStore, currentDate: @escaping () -> Date) {
        self.store = store
        self.currentDate = currentDate
    }
    
    fileprivate func cache(_ items: [FeedItem], with completion: @escaping (SaveResult) -> Void) {
        self.store.insertItems(items.toLocal(), timestamp: self.currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
    
    public func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self = self else { return }
            
            if let cacheDeletionError = error {
                completion(cacheDeletionError)
            }
            else {
                self.cache(items, with: completion)
            }
        }
    }
}

private extension Array where Element == FeedItem {
    func toLocal() -> [LocalFeedItem] {
        self.map { LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL)}
    }
}
