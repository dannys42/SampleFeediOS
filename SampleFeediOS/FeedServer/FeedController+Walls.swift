//
//  FeedController+Walls.swift
//  SampleFeediOS
//  Wall helper functions
//
//  Created by Danny Sung on 02/03/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import Foundation

// MARK: - Get Methods
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
}

// MARK: - Create Methods
public extension FeedController {
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

