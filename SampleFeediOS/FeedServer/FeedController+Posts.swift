//
//  FeedController+Posts.swift
//  SampleFeediOS
//
//  Created by Danny Sung on 02/02/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import Foundation

public extension FeedController {
    struct PostCreateModel: Codable {
        let text: String
    }
    struct PostResponseModel: Codable {
        let id: Int
        let wallId: Int
        let userId: Int
        let text: String
    }

    enum PostFailures: LocalizedError {
        case unableToReadPostList(Int,Error)

        public var errorDescription: String? {
            switch self {
            case .unableToReadPostList(let wallId, let error):
                return "Unable to read posts for wallId=\(wallId): \(error.localizedDescription)"
            }
        }
    }
    
    func createPost(wallId: Int, post: PostCreateModel, completion: @escaping (Result<PostResponseModel,Error>)->Void) {
        do {
            let postData = try JSONEncoder().encode(post)

            httpClient.postRaw(Routes.postList(wallId).endPoint, postData) { response in
            
            }
        } catch {
            completion(.failure(error))
        }
    }

    func getPosts(wallId: Int, completion: @escaping (Result<[PostResponseModel],Error>)->Void) {
        
        httpClient.getRaw(Routes.postList(wallId).endPoint) { (response) in
            switch response {
            case .failure(let error):
                completion(.failure(error))
                print("ERROR: getting post list: \(error.localizedDescription)")
            case .success(_, let data):
                let s = String(data: data, encoding: .utf8)
                print("got posts for wall \(wallId):\n\(s)")
                do {
                    let postList = try JSONDecoder().decode([PostResponseModel].self, from: data)
                    completion(.success(postList))
                } catch {
                    completion(.failure(PostFailures.unableToReadPostList(wallId, error)))
                }
            }
        }
    }

}
