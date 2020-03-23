//
//  BaseRequestRetrier.swift
//  SmartYard
//
//  Created by admin on 30/01/2020.
//  Copyright © 2020 Mad Brains. All rights reserved.
//

import Alamofire

class BaseRequestRetrier: RequestInterceptor {
    
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        return urlRequest
    }
    
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        // If task failed 5 attempts to finish, everything is very bad (connection is dead). TODO: Add Reachability
        guard request.retryCount < 5 else {
            print("REQUEST RETRIER: Task failed to finish in 5 attempts. RIP")
            return completion(.doNotRetry)
        }
        
        // If task was not completed at all (probably because of unstable connection), try it again.
        guard let response = request.task?.response as? HTTPURLResponse else {
            print("REQUEST RETRIER: Task returned no response. Trying again. Attempt #\(request.retryCount + 1)")
            return completion(.retryWithDelay(Double(request.retryCount) * 2.0))
        }
        
        if response.statusCode == 401 {
            completion(.retryWithDelay(1000))
        } else {
            completion(.doNotRetry)
        }
    }
    
}
