//
//  FeedController+Posts.swift
//  SampleFeediOS
//  Post network operations
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
    typealias PostResponse = Result<PostResponseModel, Error>
    typealias PostListResponse = Result<[PostResponseModel],Error>
    
    enum PostFailures: LocalizedError {
        case unableToReadPostList(Int,Error)
        case unableToCreatePost(Int,Error)

        public var errorDescription: String? {
            switch self {
            case .unableToReadPostList(let wallId, let error):
                return "Unable to read posts for wallId=\(wallId): \(error.localizedDescription)"
            case .unableToCreatePost(let wallId, let error):
                return "Unable to create post for wallId=\(wallId): \(error.localizedDescription)"
            }
        }
    }
    
    func createPost(wallId: Int, post: PostCreateModel, completion: @escaping (PostResponse)->Void) {
        do {
            let postData = try JSONEncoder().encode(post)

            httpClient.postRaw(Routes.postList(wallId).endPoint, postData) { response in
                switch response {
                case .failure(let error):
                    completion(.failure(error))
                case .success((_, let data)):
                    do {
                        let post = try JSONDecoder().decode(PostResponseModel.self, from: data)
                        
                        // TODO: this should be changed to update only this post to avoid unnecessary overhead when we have more posts or post content
                        self.updatePosts(wallId: wallId)
                        completion(.success(post))
                    } catch {
                        completion(.failure(PostFailures.unableToCreatePost(wallId, error)))
                    }
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func getPosts(wallId: Int, completion: @escaping (PostListResponse)->Void) {
        httpClient.getRaw(Routes.postList(wallId).endPoint) { (response) in
            switch response {
            case .failure(let error):
                completion(.failure(error))
                print("ERROR: getting post list: \(error.localizedDescription)")
            case .success(_, let data):
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
