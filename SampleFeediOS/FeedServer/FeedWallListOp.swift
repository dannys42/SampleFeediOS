//
//  FeedWallListOp.swift
//  SampleFeediOS
//  Sync list of walls visible to a user with the local CoreData cache
//
//  Created by Danny Sung on 02/02/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import Foundation
import CoreData

public class FeedWallListOp: Operation {
    var context: NSManagedObjectContext
    let feed: FeedController
    public let mode: Mode
    
    public enum Mode: Equatable {
        case all
        case singleWall(Int)
    }
    
    init(managedObjectContext: NSManagedObjectContext, mode: Mode = .all, feed: FeedController = .shared) {
        
        // setup a private managed object context for this thread
        let context = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        context.parent = managedObjectContext
        context.name = "\(Self.self)"
        context.automaticallyMergesChangesFromParent = true
        self.context = context

        self.feed = feed
        self.mode = mode
    }
    
    override public func main() {
        let g = DispatchGroup()
        
        switch mode {
        case .all:
            g.enter()
            feed.getWalls() { result in
                defer { g.leave() }
                
                switch result {
                case .success(let wallList):
                    for wallModel in wallList {
                        self.updateWall(wall: wallModel)
                    }
                case .failure(let error):
                    print("ERROR: Unable to get walls: \(error.localizedDescription)")
                }
            }
        case .singleWall(let wallId):
            g.enter()
            feed.getWall(id: wallId) { result in
                defer { g.leave() }

                switch result {
                case .success(let wallModel):
                    // Queue an update when we create to ensure responsiveness
                    self.updateWall(wall: wallModel)
                case .failure(let error):
                    print("ERROR: Unable to get wall: \(error.localizedDescription)")
                }
            }
        }
        
        g.wait()
        self.saveContext()
    }
    
    /// Update an existing wall entry if it exists, create it otherwise
    /// - Parameter wallModel: wallModel to create/update
    private func updateWall(wall wallModel: FeedController.WallResponseModel) {
        let fetchRequest = NSFetchRequest<Wall>(entityName: Wall.entity().name!)
        fetchRequest.predicate = NSPredicate(format: "id == %d", wallModel.id)

        self.context.perform {
            let existingWalls = try? fetchRequest.execute()
            let wall: Wall
        
            // If we found an existing wall, use that model
            if let existingWall = existingWalls?.first {
                wall = existingWall
            } else { // otherwise, create a new model
                wall = Wall(context: self.context)
            }
            wall.id = Int64(wallModel.id)
            wall.topic = wallModel.topic
        }
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
