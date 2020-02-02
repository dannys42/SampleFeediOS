//
//  FeedServer.swift
//  SampleFeediOS
//
//  Created by Danny Sung on 02/01/2020.
//  Copyright © 2020 Sung Heroes. All rights reserved.
//

import Foundation
import SampleUtilities

fileprivate let ServerUrl = URL(string: "http://localhost:8080")!

public class FeedServer {
    private let httpClient = SampleHTTPClient(baseUrl: ServerUrl)

    func login(username: String, password: String, completion: (Error?)->Void) {
        httpClient.login(username: username, password: password, completion: { error in
            if let error = error {
                completion(error)
                return
            }
            
            completion(nil)
        })
    }
}
