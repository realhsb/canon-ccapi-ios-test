//
//  DigestAuthInterceptor.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import Foundation
import Moya
import Alamofire
import CryptoKit

class DigestAuthInterceptor: RequestInterceptor {
    private let authManager: DigestAuthenticationManager
    
    init(authManager: DigestAuthenticationManager) {
        self.authManager = authManager
    }
    
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var urlRequest = urlRequest
        
        if var digestInfo = authManager.getCachedDigestInfo() {
            let path = urlRequest.url?.path ?? "/"
            let method = urlRequest.httpMethod ?? "GET"
            
            let authHeader = authManager.createAuthorizationHeader(
                digestInfo: digestInfo,
                method: method,
                uri: path
            )
            
            urlRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
            
            // 디버깅용 로그
            print("🔐 Adding Authorization header")
            print("Path: \(path)")
            print("Auth: \(authHeader)")
            
            digestInfo.incrementNc()
            authManager.updateDigestInfo(digestInfo)
        } else {
            print("⚠️ No cached digest info")
        }
        
        completion(.success(urlRequest))
    }
    
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            print("❌ Not a 401 error, not retrying")
            completion(.doNotRetry)
            return
        }
        
        guard let wwwAuthHeader = response.value(forHTTPHeaderField: "WWW-Authenticate") else {
            print("❌ No WWW-Authenticate header")
            completion(.doNotRetry)
            return
        }
        
        print("🔑 Received 401, parsing digest challenge")
        print("WWW-Authenticate: \(wwwAuthHeader)")
        
        guard let digestInfo = authManager.parseDigestChallenge(from: wwwAuthHeader) else {
            print("❌ Failed to parse digest challenge")
            completion(.doNotRetry)
            return
        }
        
        print("✅ Digest info parsed successfully")
        authManager.updateDigestInfo(digestInfo)
        
        // 재시도
        completion(.retry)
    }
}
