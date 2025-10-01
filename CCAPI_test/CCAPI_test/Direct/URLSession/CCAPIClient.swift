//
//  CCAPIClient.swift
//  CCAPI_test
//
//  Created by Subeen on 10/1/25.
//

import Foundation

class CCAPIClient {
    private let baseURL = "https://192.168.1.2:443/ccapi"
    private var digestAuth: HTTPDigestAuth?
    private var session: URLSession
    private let sessionDelegate = SSLPinningDelegate()
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        // 자체 서명 인증서 허용 (개발 환경용)
        self.session = URLSession(configuration: config, delegate: sessionDelegate, delegateQueue: nil)
        
        print("🚀 CCAPIClient initialized")
        print("   Base URL: \(baseURL)")
        print("   Session delegate: \(sessionDelegate)")
    }
    
    // 연결 테스트 함수
    func testConnection(completion: @escaping (String) -> Void) {
        guard let url = URL(string: baseURL) else {
            completion("ERROR: Invalid URL - \(baseURL)")
            return
        }
        
        print("========================================")
        print("CONNECTION TEST START")
        print("URL: \(baseURL)")
        print("========================================")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        let task = session.dataTask(with: request) { data, response, error in
            var result = "========================================\n"
            result += "CONNECTION TEST RESULT\n"
            result += "========================================\n"
            
            if let error = error {
                result += "ERROR: \(error.localizedDescription)\n"
                if let urlError = error as? URLError {
                    result += "URLError Code: \(urlError.code.rawValue)\n"
                    result += "Failure Reason: \(urlError.failureURLString ?? "none")\n"
                }
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                result += "Status Code: \(httpResponse.statusCode)\n"
                result += "Headers:\n"
                for (key, value) in httpResponse.allHeaderFields {
                    result += "  \(key): \(value)\n"
                }
            } else {
                result += "No HTTP Response\n"
            }
            
            if let data = data {
                result += "Data received: \(data.count) bytes\n"
            }
            
            result += "========================================\n"
            print(result)
            completion(result)
        }
        
        task.resume()
    }
    
    
    func authenticate(username: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let url = URL(string: baseURL) else {
            print("❌ Invalid URL: \(baseURL)")
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }
        
        print("🔄 Attempting to connect to: \(baseURL)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10.0
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Connection error: \(error.localizedDescription)")
                if let urlError = error as? URLError {
                    print("   URLError code: \(urlError.code.rawValue)")
                    print("   Error description: \(urlError.localizedDescription)")
                }
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ Invalid HTTP response")
                completion(.failure(NSError(domain: "InvalidResponse", code: -1)))
                return
            }
            
            print("✅ Received HTTP response: \(httpResponse.statusCode)")
            print("   Headers: \(httpResponse.allHeaderFields)")
            
            if httpResponse.statusCode == 401 {
                // WWW-Authenticate 헤더 추출 (대소문자 구분 없이)
                var wwwAuthHeader: String?
                for (key, value) in httpResponse.allHeaderFields {
                    if let keyString = key as? String,
                       keyString.lowercased() == "www-authenticate",
                       let valueString = value as? String {
                        wwwAuthHeader = valueString
                        break
                    }
                }
                
                if let wwwAuthHeader = wwwAuthHeader {
                    print("Received 401, WWW-Authenticate: \(wwwAuthHeader)")
                    
                    // Digest Auth 객체 생성
                    self.digestAuth = HTTPDigestAuth(username: username, password: password)
                    
                    // 인증 헤더 생성
                    if let authHeader = self.digestAuth?.getDigestAuthHeader(
                        method: "GET",
                        url: url.absoluteString,
                        body: nil,
                        wwwAuthHeader: wwwAuthHeader
                    ) {
                        // 인증 헤더로 재요청
                        self.sendAuthenticatedRequest(url: url, authHeader: authHeader, completion: completion)
                    } else {
                        completion(.failure(NSError(domain: "AuthHeaderGenerationFailed", code: -1)))
                    }
                } else {
                    completion(.failure(NSError(domain: "NoWWWAuthenticateHeader", code: -1)))
                }
            } else if httpResponse.statusCode == 200 {
                print("Authentication successful")
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "UnexpectedStatusCode", code: httpResponse.statusCode)))
            }
        }
        
        task.resume()
    }
    
    private func sendAuthenticatedRequest(url: URL, authHeader: String, completion: @escaping (Result<Void, Error>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        
        let task = session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "InvalidResponse", code: -1)))
                return
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 202 {
                print("Authenticated request successful")
                if let data = data, let responseString = String(data: data, encoding: .utf8) {
                    print("Response: \(responseString)")
                }
                completion(.success(()))
            } else {
                print("Authentication failed with status: \(httpResponse.statusCode)")
                completion(.failure(NSError(domain: "AuthenticationFailed", code: httpResponse.statusCode)))
            }
        }
        
        task.resume()
    }
    
    // 인증된 API 호출 예시
    // 인증된 API 호출 예시
    func makeAuthenticatedRequest(endpoint: String, method: String = "GET", body: Data? = nil, completion: @escaping (Result<Data, Error>) -> Void) {
        guard let digestAuth = digestAuth else {
            completion(.failure(NSError(domain: "NotAuthenticated", code: -1)))
            return
        }
        
        let urlString = "\(baseURL)/\(endpoint)"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "InvalidURL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        
        // 인증 헤더 생성 (이전 nonce 재사용)
        if let authHeader = digestAuth.getDigestAuthHeader(
            method: method,
            url: urlString,
            body: body,
            wwwAuthHeader: nil
        ) {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "InvalidResponse", code: -1)))
                return
            }
            
            // 401 응답 시 재인증 시도
            if httpResponse.statusCode == 401 {
                print("Received 401, attempting re-authentication...")
                
                // WWW-Authenticate 헤더 추출 (대소문자 구분 없이)
                var wwwAuthHeader: String?
                for (key, value) in httpResponse.allHeaderFields {
                    if let keyString = key as? String,
                       keyString.lowercased() == "www-authenticate",
                       let valueString = value as? String {
                        wwwAuthHeader = valueString
                        break
                    }
                }
                
                if let wwwAuthHeader = wwwAuthHeader,
                   let authHeader = self?.digestAuth?.getDigestAuthHeader(
                    method: method,
                    url: urlString,
                    body: body,
                    wwwAuthHeader: wwwAuthHeader
                   ) {
                    // 재시도
                    var retryRequest = URLRequest(url: url)
                    retryRequest.httpMethod = method
                    retryRequest.httpBody = body
                    retryRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
                    
                    let retryTask = self?.session.dataTask(with: retryRequest) { data, response, error in
                        if let error = error {
                            completion(.failure(error))
                            return
                        }
                        
                        guard let httpResponse = response as? HTTPURLResponse else {
                            completion(.failure(NSError(domain: "InvalidResponse", code: -1)))
                            return
                        }
                        
                        if httpResponse.statusCode == 200 || httpResponse.statusCode == 202 {
                            completion(.success(data ?? Data()))
                        } else {
                            completion(.failure(NSError(domain: "RequestFailed", code: httpResponse.statusCode)))
                        }
                    }
                    retryTask?.resume()
                    return
                }
            }
            
            if httpResponse.statusCode == 200 || httpResponse.statusCode == 202 {
                completion(.success(data ?? Data()))
            } else {
                completion(.failure(NSError(domain: "RequestFailed", code: httpResponse.statusCode)))
            }
        }
        
        task.resume()
    }
}

