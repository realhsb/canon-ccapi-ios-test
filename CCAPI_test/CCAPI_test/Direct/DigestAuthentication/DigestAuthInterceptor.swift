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

// MARK: - Digest Auth Interceptor
/// Alamofire의 RequestInterceptor를 구현하여 자동으로 Digest 인증을 처리합니다
class DigestAuthInterceptor: RequestInterceptor {
    private let authManager: DigestAuthenticationManager
    
    init(authManager: DigestAuthenticationManager) {
        self.authManager = authManager
    }
    
    /// 요청을 보내기 직전에 호출됩니다
    /// 캐시된 Digest 정보가 있으면 Authorization 헤더를 추가합니다
    func adapt(
        _ urlRequest: URLRequest,
        for session: Session,
        completion: @escaping (Result<URLRequest, Error>) -> Void
    ) {
        var urlRequest = urlRequest
        
        // 캐시된 Digest 정보가 있는지 확인
        if var digestInfo = authManager.getCachedDigestInfo() {
            let path = urlRequest.url?.path ?? ""
            let method = urlRequest.httpMethod ?? "GET"
            
            // Authorization 헤더 생성 및 추가
            let authHeader = authManager.createAuthorizationHeader(
                digestInfo: digestInfo,
                method: method,
                uri: path
            )
            
            urlRequest.setValue(authHeader, forHTTPHeaderField: "Authorization")
            
            // nc 값 증가 (다음 요청을 위해)
            digestInfo.incrementNc()
            authManager.updateDigestInfo(digestInfo)
        }
        
        completion(.success(urlRequest))
    }
    
    /// 요청이 실패했을 때 호출됩니다
    /// 401 응답인 경우 Digest challenge를 파싱하고 재시도합니다
    func retry(
        _ request: Request,
        for session: Session,
        dueTo error: Error,
        completion: @escaping (RetryResult) -> Void
    ) {
        // 401 Unauthorized 응답인지 확인
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            completion(.doNotRetry)
            return
        }
        
        // WWW-Authenticate 헤더에서 Digest challenge 추출
        guard let wwwAuthHeader = response.value(forHTTPHeaderField: "WWW-Authenticate"),
              let digestInfo = authManager.parseDigestChallenge(from: wwwAuthHeader) else {
            completion(.doNotRetry)
            return
        }
        
        // Digest 정보 저장 후 재시도
        authManager.updateDigestInfo(digestInfo)
        completion(.retry)
    }
}
