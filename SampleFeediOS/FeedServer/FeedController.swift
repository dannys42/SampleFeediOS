//
//  FeedController.swift
//  SampleFeediOS
//
//  Created by Danny Sung on 02/01/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import Foundation
import CoreData
import SampleFeedUtilities

fileprivate let ServerUrl = URL(string: "http://localhost:8080")!

public class FeedController {
    static let shared = FeedController()
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
        
        self.httpClient = SampleHTTPClient(baseUrl: ServerUrl)
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

// MARK: - Walls
public extension FeedController {
    enum WallFailures: LocalizedError {
        case unableToReadWallList(Error)
        case unableToConvertWallCreateModelToJSON(Error)
        case unableToDecodeJSONasWallResponse(Error)
        
        public var errorDescription: String? {
            switch self {
            case .unableToReadWallList(let error):
                return "Unable to read wall list: \(error.localizedDescription)"
            case .unableToConvertWallCreateModelToJSON(let error):
                return "Unable to convert WallCreate model to JSON: \(error.localizedDescription)"
            case .unableToDecodeJSONasWallResponse(let error):
                return "Unable to decode JSON as WallResponse: \(error.localizedDescription)"
            }
        }
    }

    struct WallResponseModel: Codable {
        let id: Int
        let topic: String
        let userId: Int
        let isPublic: Bool
    }
    func getWalls(completion: @escaping (Result<[WallResponseModel], Error>)->Void) {
        httpClient.getRaw(Routes.wallList.endPoint) { response in
            switch response {
            case .failure(let error):
                completion(.failure(error))
            case .success(_, let data):
                do {
                    let wallList = try JSONDecoder().decode([WallResponseModel].self, from: data)
                    completion(.success(wallList))
                } catch {
                    completion(.failure(WallFailures.unableToReadWallList(error)))
                }
            }
        }
    }
    func getWall(id: Int, completion: @escaping (Result<WallResponseModel,Error>)->Void) {
        httpClient.getRaw(Routes.wall(id).endPoint) { response in
            switch response {
            case .failure(let error):
                completion(.failure(error))
            case .success(_, let data):
                do {
                    let wall = try JSONDecoder().decode(WallResponseModel.self, from: data)
                    completion(.success(wall))
                } catch {
                    completion(.failure(WallFailures.unableToReadWallList(error)))
                }
            }
        }
    }

    struct WallCreateModel: Codable {
        let topic: String
        let isPublic: Bool
    }
    enum CreateWallResponse {
        case success(WallResponseModel)
        case failure(Error)
    }
    func createWall(topic: String, isPublic: Bool, completion: @escaping (CreateWallResponse)->Void = { _ in }) {
        let wall = WallCreateModel(topic: topic, isPublic: isPublic)
        
        do {
            let wallData = try JSONEncoder().encode(wall)
            httpClient.postRaw(Routes.wallList.endPoint, wallData) { (response) in
                switch response {
                case .failure(let error):
                    print("error: \(error.localizedDescription)")
                    completion(.failure(error))
                case .success(_, let data):
                    do {
                        let wallModel = try JSONDecoder().decode(WallResponseModel.self, from: data)
                        self.updateWall(wallId: wallModel.id)
                        completion(.success(wallModel))
                    } catch {
                        completion(.failure(WallFailures.unableToDecodeJSONasWallResponse(error)))
                    }
                }
            }
        } catch {
            completion(.failure(WallFailures.unableToConvertWallCreateModelToJSON(error)))
        }
    }

}

