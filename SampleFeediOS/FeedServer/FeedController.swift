//
//  FeedController.swift
//  SampleFeediOS
//
//  This controller is used to trigger network operations.
//
//  Created by Danny Sung on 02/01/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import Foundation
import CoreData
import SampleFeedUtilities

public class FeedController {
    static let productionUrl = URL(string: "http://localhost:8080")!
    static let shared = FeedController()

    public var serverUrl = FeedController.productionUrl
    internal let opQ: OperationQueue
    
    /// store operations will occur on a child of this managed object context
    public var parentManagedObjectContext: NSManagedObjectContext? = nil
    
    enum Routes {
        case wallList
        case wall(Int)
        case postList(Int)
        
        var endPoint: String {
            switch self {
            case .wallList: return "/walls"
            case .wall(let id): return "/walls/\(id)"
            case .postList(let wallId): return "/walls/\(wallId)/posts"
            }
        }
    }
    
    internal let httpClient: SampleHTTPClient
    
    init() {
        self.opQ = OperationQueue()
        
        self.opQ.maxConcurrentOperationCount = 3
        
        self.httpClient = SampleHTTPClient(baseUrl: serverUrl)
        self.httpClient.defaultHeaders = [
            "Content-Type" : "application/json"
        ]
    }

    func login(username: String, password: String, completion: @escaping (Error?)->Void) {
        httpClient.login(username: username, password: password, completion: { error in
            if let error = error {
                completion(error)
                return
            }
            
            completion(nil)
        })
    }
    
    func logout() {
        try? httpClient.logout()
    }
    
    // MARK: - Data Synchronization methods
    
    /// Synchronize walls from the server to the local store.
    /// This will do nothing if an identical existing request is already running
    func updateWalls() {
        guard let context = self.parentManagedObjectContext else { return }
        
        let wallListOps = self.opQ.operations
            .compactMap { $0 as? FeedWallListOp }
            .compactMap { $0.mode == FeedWallListOp.Mode.all }
        guard wallListOps.count == 0 else {
            return
        }

        let op = FeedWallListOp(managedObjectContext: context, feed: self)
        self.opQ.addOperation(op)
    }
    
    /// Synchronize a single wall with the local store.
    /// This will do nothing if an identical existing request is already running
    /// - Parameter wallId: The wallId to synchronize
    func updateWall(wallId: Int) {
        guard let context = self.parentManagedObjectContext else { return }
        
        let wallListOps = self.opQ.operations
            .compactMap { $0 as? FeedWallListOp }
            .compactMap { $0.mode == FeedWallListOp.Mode.singleWall(wallId) }
        guard wallListOps.count == 0 else {
            // do nothing if an update op with this wallId already exists
            return
        }

        let op = FeedWallListOp(managedObjectContext: context, mode: .singleWall(wallId), feed: self)
        self.opQ.addOperation(op)
    }
    
    /// Synchronize posts for a given wall to the local store
    /// This will do nothing if an identical existing request is already running
    func updatePosts(wallId: Int) {
        guard let context = self.parentManagedObjectContext else { return }

        let wallListOps = self.opQ.operations
            .compactMap { $0 as? FeedPostsOp }
            .compactMap { $0.wallId == wallId }
        guard wallListOps.count == 0 else {
            // do nothing if an update op with this wallId already exists
            return
        }

        let op = FeedPostsOp(wallId: wallId, managedObjectContext: context, feed: self)
        self.opQ.addOperation(op)
    }
}

