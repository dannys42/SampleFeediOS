//
//  FeedPostsOp.swift
//  SampleFeediOS
//  Sync posts of a wall with the local CoreData cache
//
//  Created by Danny Sung on 02/02/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import Foundation
import CoreData

public class FeedPostsOp: Operation {
    var context: NSManagedObjectContext
    let feed: FeedController
    public let wallId: Int
    
    init(wallId: Int, managedObjectContext: NSManagedObjectContext, feed: FeedController = .shared) {
        // setup a private managed object context for this thread
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = managedObjectContext
        context.name = "\(Self.self)"
        context.automaticallyMergesChangesFromParent = true
        self.context = context
        self.wallId = wallId
        self.feed = feed
    }
    
    override public func main() {
        let g = DispatchGroup()
        
        g.enter()
        feed.getPosts(wallId: wallId) { result in
            defer { g.leave() }
            switch result {
            case .failure(let error):
                print("got error: \(error.localizedDescription)")
                break
            case .success(let postList):
                print("success: \(postList)")
                break
            }
        }
        
        g.wait()
        self.saveContext()
    }
    
    private func saveContext() {
        self.context.perform {
            do {
                try self.context.save()
            } catch {
                print("ERROR: Unable to save context (\(#file)): \(error)")
            }
        }
    }
}
