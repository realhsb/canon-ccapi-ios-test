//
//  DigestAuthInterceptor.swift
//  CCAPI_test
//
//  Created by Subeen on 10/6/25.
//

import Foundation
import Alamofire

/// Alamofire RequestInterceptor로 Digest 인증 자동 처리
class DigestAuthInterceptor: RequestInterceptor {
    
    private let username: String
    private let password: String
    private var digestAuth: HTTPDigestAuth?
    private var isAuthenticated = false
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    // MARK: - RequestInterceptor
    
    /// 요청 전 Authorization 헤더 추가
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        
        // Digest Auth 객체가 있으면 헤더 추가
        if let digestAuth = digestAuth,
           let url = urlRequest.url?.absoluteString,
           let method = urlRequest.httpMethod {
            
            let authHeader = digestAuth.getDigestAuthHeader(
                method: method,
                url: url,
                body: urlRequest.httpBody,
                wwwAuthHeader: nil  // 기존 nonce 재사용
            )
            
            if let authHeader = authHeader {
                urlRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
                print("Authorization header added for: \(url)")
            }
        }
        
        completion(.success(urlRequest))
    }
    
    /// 401 응답 시 재시도 처리
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse else {
            completion(.doNotRetry)
            return
        }
        
        // 401 Unauthorized 처리
        if response.statusCode == 401 {
            print("Received 401, attempting to refresh auth")
            
            // WWW-Authenticate 헤더 추출
            guard let wwwAuthHeader = extractWWWAuthenticateHeader(from: response) else {
                print("No WWW-Authenticate header found")
                completion(.doNotRetry)
                return
            }
            
            print("WWW-Authenticate: \(wwwAuthHeader)")
            
            // Digest Auth 초기화 또는 갱신
            if digestAuth == nil {
                digestAuth = HTTPDigestAuth(username: username, password: password)
            }
            
            // 새 nonce로 헤더 갱신
            guard let urlRequest = request.request,
                  let url = urlRequest.url?.absoluteString,
                  let method = urlRequest.httpMethod else {
                completion(.doNotRetry)
                return
            }
            
            _ = digestAuth?.getDigestAuthHeader(
                method: method,
                url: url,
                body: urlRequest.httpBody,
                wwwAuthHeader: wwwAuthHeader
            )
            
            // 재시도
            completion(.retry)
            return
        }
        
        // 그 외 에러는 재시도하지 않음
        completion(.doNotRetry)
    }
    
    // MARK: - Helper
    
    private func extractWWWAuthenticateHeader(from response: HTTPURLResponse) -> String? {
        for (key, value) in response.allHeaderFields {
            if let keyString = key as? String,
               keyString.lowercased() == "www-authenticate",
               let valueString = value as? String {
                return valueString
            }
        }
        return nil
    }
    
    /// 인증 상태 리셋
    func resetAuthentication() {
        digestAuth = nil
        isAuthenticated = false
        print("DigestAuthInterceptor reset")
    }
}
