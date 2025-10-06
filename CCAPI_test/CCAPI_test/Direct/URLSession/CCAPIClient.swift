//
//  CCAPIClient.swift
//  CCAPI_test
//
//  Created by Subeen on 10/1/25.
//

import Foundation

/// Canon CCAPI 클라이언트
/// Digest 인증을 사용하여 카메라와 통신
class CCAPIClient {
    static let shared = CCAPIClient()
    
    private let baseURL = "https://192.168.1.2:443/ccapi"
    private var digestAuth: HTTPDigestAuth?
    private var session: URLSession
    private let sessionDelegate = SSLPinningDelegate()
    private var isAuthenticated = false
    private var authErrorCount = 0
    private let maxAuthRetries = 10
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config, delegate: sessionDelegate, delegateQueue: nil)
        
        print("CCAPIClient initialized")
        print("  Base URL: \(baseURL)")
    }
    
    // MARK: - Authentication
    
    /// 카메라 인증 수행
    /// - Parameters:
    ///   - username: 사용자명
    ///   - password: 비밀번호
    func authenticate(username: String, password: String) async throws {
        // 이미 인증되어 있으면 스킵
        if isAuthenticated && digestAuth != nil {
            print("Already authenticated, skipping...")
            return
        }
        
        guard let url = URL(string: baseURL) else {
            throw CCAPIError.invalidURL
        }
        
        print("Attempting to authenticate: \(baseURL)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CCAPIError.invalidResponse
        }
        
        print("Received HTTP response: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 401 {
            // WWW-Authenticate 헤더 추출
            guard let wwwAuthHeader = extractWWWAuthenticateHeader(from: httpResponse) else {
                throw CCAPIError.noWWWAuthenticateHeader
            }
            
            print("WWW-Authenticate header found")
            
            // Digest Auth 객체 생성
            digestAuth = HTTPDigestAuth(username: username, password: password)
            
            // 인증 헤더 생성
            guard let authHeader = digestAuth?.getDigestAuthHeader(
                method: "GET",
                url: url.absoluteString,
                body: nil,
                wwwAuthHeader: wwwAuthHeader
            ) else {
                throw CCAPIError.authHeaderGenerationFailed
            }
            
            // 인증 헤더로 재요청
            var authRequest = URLRequest(url: url)
            authRequest.httpMethod = "GET"
            authRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
            
            let (_, authResponse) = try await session.data(for: authRequest)
            
            guard let authHttpResponse = authResponse as? HTTPURLResponse else {
                throw CCAPIError.invalidResponse
            }
            
            if authHttpResponse.statusCode == 200 || authHttpResponse.statusCode == 202 {
                print("Authentication successful")
                isAuthenticated = true
                authErrorCount = 0
            } else {
                print("Authentication failed with status: \(authHttpResponse.statusCode)")
                throw CCAPIError.authenticationFailed(authHttpResponse.statusCode)
            }
        } else if httpResponse.statusCode == 200 {
            print("No authentication required")
            isAuthenticated = true
        } else {
            throw CCAPIError.unexpectedStatusCode(httpResponse.statusCode)
        }
    }
    
    // MARK: - API Request
    
    /// 인증된 API 요청 수행
    /// - Parameters:
    ///   - endpoint: API 엔드포인트 (예: "ver100/shooting/settings/iso")
    ///   - method: HTTP 메서드 (기본값: GET)
    ///   - body: 요청 바디 (optional)
    /// - Returns: 응답 데이터
    func makeRequest(endpoint: String, method: String = "GET", body: Data? = nil) async throws -> Data {
        guard digestAuth != nil else {
            throw CCAPIError.notAuthenticated
        }
        
        var retryCount = 0
        
        // while 루프로 재시도 (안드로이드 방식과 유사)
        while retryCount <= maxAuthRetries {
            let urlString = "\(baseURL)/\(endpoint)"
            guard let url = URL(string: urlString) else {
                throw CCAPIError.invalidURL
            }
            
            var request = URLRequest(url: url)
            request.httpMethod = method
            request.httpBody = body
            
            // Authorization 헤더 생성
            if let authHeader = digestAuth?.getDigestAuthHeader(
                method: method,
                url: urlString,
                body: body,
                wwwAuthHeader: nil  // 이전 nonce 재사용
            ) {
                request.setValue(authHeader, forHTTPHeaderField: "Authorization")
            }
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CCAPIError.invalidResponse
            }
            
            print("Response status: \(httpResponse.statusCode) for \(endpoint)")
            
            // 401 응답 - 재인증 시도
            if httpResponse.statusCode == 401 {
                retryCount += 1
                authErrorCount += 1
                
                print("Received 401, retry attempt: \(retryCount)/\(maxAuthRetries)")
                
                if retryCount > maxAuthRetries {
                    print("Max retries exceeded")
                    isAuthenticated = false
                    digestAuth = nil
                    authErrorCount = 0
                    throw CCAPIError.maxRetriesExceeded
                }
                
                // WWW-Authenticate 헤더로 nonce 갱신
                if let wwwAuthHeader = extractWWWAuthenticateHeader(from: httpResponse) {
                    print("Updating nonce from new WWW-Authenticate header")
                    _ = digestAuth?.getDigestAuthHeader(
                        method: method,
                        url: urlString,
                        body: body,
                        wwwAuthHeader: wwwAuthHeader
                    )
                }
                
                // 다음 루프에서 재시도
                continue
            }
            
            // 성공
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 202 {
                authErrorCount = 0
                print("Request successful: \(data.count) bytes received")
                return data
            }
            
            // 그 외 에러
            throw CCAPIError.unexpectedStatusCode(httpResponse.statusCode)
        }
        
        throw CCAPIError.maxRetriesExceeded
    }
    
    // MARK: - Helper Methods
    
    /// HTTP 응답에서 WWW-Authenticate 헤더 추출 (대소문자 무시)
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
        isAuthenticated = false
        digestAuth = nil
        authErrorCount = 0
        print("Authentication reset")
    }
}
