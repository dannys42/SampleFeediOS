//
//  FeedNet.swift
//  Network calls related to the feed
//
//  Created by Danny Sung on 02/01/2020.
//

import Foundation

public class FeedNet {
    internal let httpClient: SampleHTTPClient
    
    public init(httpClient: SampleHTTPClient) {
        self.httpClient = httpClient
    }

}
