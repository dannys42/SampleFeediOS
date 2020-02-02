//
//  HTTPClient+Async.swift
//  
//
//  Created by Danny Sung on 02/01/2020.
//

import Foundation

public extension SampleHTTPClient {
    enum AsyncRawResponse {
        case success(HTTPURLResponse, Data)
        case failure(Error)
    }
    enum AsyncKeyedResponse {
        case success(HTTPURLResponse, KeyedData)
        case failure(Error)
    }
    
    /// Make an asynchronous HTTP call with Data input/output types
    /// - Parameters:
    ///   - request: URLRequest
    ///   - timeout: timeout to use
    @discardableResult
    func async(request: URLRequest, completion: @escaping (AsyncRawResponse)->Void ) -> URLSessionDataTask {
        let task = s.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let response = response as? HTTPURLResponse else {
                completion(.failure(Failures.noHTTPResponse))
                return
            }
            guard let data = data else {
                completion(.failure(Failures.noData))
                return
            }
            
            completion(.success(response, data))
        }
        task.resume()
        return task
    }

    /// Make an asynchronous HTTP call with input/output dictionaries
    /// - Parameters:
    ///   - url: URL to connect to
    ///   - headers: Optional header fields to include
    ///   - body: JSON data to send
    ///   - timeout: Optional timeout
    @discardableResult
    func async(method: HTTPMethod,
                     url: URL,
                     headers: HttpHeaders=[:],
                     body: KeyedData? = nil,
                     completion: @escaping (AsyncKeyedResponse)->Void) -> URLSessionDataTask? {
        
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
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: body,
                                                  options: .prettyPrinted)
                req.httpBody = jsonData
            } catch {
                completion(.failure(error))
                return nil
            }
        }
        
        // Perform the HTTP request
        let task = self.async(request: req) { (response) in
            switch response {
            case .failure(let error):
                completion(.failure(error))
            case .success(let httpResponse, let data):
                // Convert the data to an object
                do {
                    let returnData = try JSONSerialization.jsonObject(with: data,
                                                              options: [])
                    guard let returnDict = returnData as? [String : Any] else {
                        completion(.failure(Failures.cannotDecodeData))
                        return
                    }
                    
                    completion(.success(httpResponse, returnDict))
                } catch {
                    completion(.failure(error))
                    return
                }
            }
        }
        return task
    }
}
