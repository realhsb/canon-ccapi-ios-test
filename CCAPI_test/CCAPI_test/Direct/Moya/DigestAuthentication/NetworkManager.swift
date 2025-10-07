//
//  NetworkManager.swift
//  CCAPI_test
//
//  Created by Subeen on 10/6/25.
//

import Foundation
import Moya
import Alamofire

/// Moya Provider와 Digest 인증을 통합 관리하는 싱글톤
class NetworkManager {
    static let shared = NetworkManager()
    
    private let username = "user"
    private let password = "0000"  // 실제 비밀번호로 변경
    
    private let interceptor: DigestAuthInterceptor
    private let session: Session
    
    /// CCAPI Provider
    lazy var ccapiProvider: MoyaProvider<ShootingTarget> = {
        return MoyaProvider<ShootingTarget>(
            session: session,
            plugins: [
                NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))
            ]
        )
    }()
    
    private init() {
        // Digest Auth Interceptor 생성
        interceptor = DigestAuthInterceptor(username: username, password: password)
        
        // SSL 인증서 처리를 위한 ServerTrustManager 설정
        let serverTrustManager = ServerTrustManager(evaluators: [
            "192.168.1.2": DisabledTrustEvaluator()  // 자체 서명 인증서 허용
        ])
        
        // Alamofire Session 설정
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        
        session = Session(
            configuration: configuration,
            interceptor: interceptor,
            serverTrustManager: serverTrustManager
        )
        
        print("NetworkManager initialized")
        print("  Username: \(username)")
    }
    
    /// 인증 상태 리셋
    func resetAuthentication() {
        interceptor.resetAuthentication()
        print("NetworkManager authentication reset")
    }
}
