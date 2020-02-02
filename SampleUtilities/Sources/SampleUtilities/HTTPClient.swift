//
//  HTTPClient.swift
//  A simple HTTP Client library
//
//  Created by Danny Sung on 01/31/2020.
//

import Foundation

public class SampleHTTPClient: NSObject {
    public typealias HttpHeaders = [String:String]
    public typealias KeyedData = [String:Any]
    
    internal var s = URLSession()
    public static let defaultTimeout: TimeInterval = 3.0 // Should be longer in production
    
    public var baseUrl: URL
    public var defaultHeaders: HttpHeaders = [:]
    public var defaultTimeout: TimeInterval = SampleHTTPClient.defaultTimeout

    public enum Failures: Error {
        case timeout
        case noHTTPResponse
        case noData
        case cannotDecodeData
    }
    
    public enum HTTPMethod: CustomStringConvertible {
        case get
        case post
        case put
        case delete
        case custom(String)
        
        public var description: String {
            switch self {
            case .get: return "GET"
            case .put: return "PUT"
            case .post: return "POST"
            case .delete: return "DELETE"
            case .custom(let string): return string
            }
        }

    }

    public init(baseUrl: URL, configuration: URLSessionConfiguration = .default) {
        self.baseUrl = baseUrl
        super.init()
        self.s = URLSession(configuration: configuration,
                            delegate: self,
                            delegateQueue: nil)
    }
    
    /// Make a synchronous HTTP call with Data input/output types
    /// - Parameters:
    ///   - request: URLRequest
    ///   - timeout: timeout to use
    public func sync(request: URLRequest, timeout: TimeInterval) throws -> (HTTPURLResponse, Data) {
        var returnData: Data?
        var returnError: Error?
        var returnResponse: HTTPURLResponse?
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = s.dataTask(with: request) { (data, response, error) in
            returnData = data
            returnError = error
            returnResponse = response as? HTTPURLResponse
            semaphore.signal()
        }
        task.resume()
        
        let waitResult = semaphore.wait(timeout: .now() + timeout)
        if waitResult == .timedOut {
            task.cancel()
            throw Failures.timeout
        }
        
        if let error = returnError {
            throw error
        }
        guard let response = returnResponse else {
            throw Failures.noHTTPResponse
        }
        guard let data = returnData else {
            throw Failures.noData
        }
        return (response, data)
    }
    
    /// Make a synchronous HTTP call
    /// - Parameters:
    ///   - url: URL to connect to
    ///   - headers: Optional header fields to include
    ///   - body: JSON data to send
    ///   - timeout: Optional timeout
    public func sync(method: HTTPMethod,
                     url: URL,
                     headers: [String:String]=[:],
                     body: [String:Any]? = nil,
                     timeout: TimeInterval = SampleHTTPClient.defaultTimeout) throws -> (HTTPURLResponse, [String:Any]) {
        var req = URLRequest(url: url)
        req.httpMethod = method.description
        
        // Setup HTTP Headers
        for (key,value) in self.defaultHeaders {
            req.addValue(value, forHTTPHeaderField: key)
        }
        for (key,value) in headers {
            req.addValue(value, forHTTPHeaderField: key)
        }
        
        // Setup body of HTTP message
        // Pretty printing for debug.  (Should be removed in production for performance)
        if let body = body {
            let jsonData = try JSONSerialization.data(withJSONObject: body,
                                                  options: .prettyPrinted)
            req.httpBody = jsonData
        }
        
        // Perform the HTTP request
        let (response, data) =
            try self.sync(request: req, timeout: timeout)
        
        // Convert the data to an object
        let returnData = try JSONSerialization.jsonObject(with: data,
                                                      options: [])
        guard let returnDict = returnData as? [String : Any] else {
            throw Failures.cannotDecodeData
        }
        return (response, returnDict)
    }
}

extension SampleHTTPClient: URLSessionTaskDelegate {
    
}
