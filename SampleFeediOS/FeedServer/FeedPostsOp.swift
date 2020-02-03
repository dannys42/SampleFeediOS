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

        // Posts will go nowhere if we don't have a wall reference to associate it with
        guard let wall = self.getWall(id: wallId) else {
            print("ERROR: wall not found: \(wallId)")
            return
        }

        g.enter()
        
        feed.getPosts(wallId: wallId) { result in
            defer { g.leave() }
            switch result {
            case .failure(let error):
                print("got error: \(error.localizedDescription)")
                break
            case .success(let postList):
                for postModel in postList {
                    self.update(postModel: postModel, wall: wall)
                }
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
    
    private func getWall(id: Int) -> Wall? {
        var wall: Wall?
        
        self.context.performAndWait {
            let fetchRequest = NSFetchRequest<Wall>(entityName: Wall.entity().name!)
            fetchRequest.predicate = NSPredicate(format: "id == %d", id)
            let walls = try? fetchRequest.execute()
            wall = walls?.first
        }

        return wall
    }
    /// Update an existing post entry if it exists, create it otherwise
    /// - Parameter postModel: postModel to create/update
    private func update(postModel: FeedController.PostResponseModel, wall: Wall) {
        let fetchRequest = NSFetchRequest<Post>(entityName: Post.entity().name!)
        fetchRequest.predicate = NSPredicate(format: "id == %d", postModel.id)

        self.context.perform {
            let existingPosts = try? fetchRequest.execute()
            let post: Post
        
            // If we found an existing wall, use that model
            if let existingPost = existingPosts?.first {
                post = existingPost
            } else { // otherwise, create a new model
                post = Post(context: self.context)
            }
            post.id = Int64(postModel.id)
            post.text = postModel.text
            post.wall = wall
        }
        self.saveContext()
    }
}
