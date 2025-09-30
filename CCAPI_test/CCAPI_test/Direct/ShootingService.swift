//
//  CameraService.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import Foundation
import Combine
import CombineMoya
import Moya
import SwiftUI
import Alamofire

protocol ShootingServiceType {
    func getISO() async throws -> SettingResponse
    func putISO(value: String) async throws -> SettingResponse
}

final class ShootingService: ShootingServiceType {
    
    private let jsonDecoder = JSONDecoder()
//    let provider = MoyaProvider<ShootingTarget>(plugins: [MoyaLoggingPlugin()])
//    let provider = MoyaProvider<ShootingTarget>(
//        session: unsafeSession,
//        plugins: [MoyaLoggingPlugin()]
//    )
    var provider = MoyaProvider<ShootingTarget>()
    
    init(username: String, password: String) {
        // 1. Digest 인증 매니저 생성
            let authManager = DigestAuthenticationManager(username: username, password: password)
            
            // 2. Interceptor 생성
            let interceptor = DigestAuthInterceptor(authManager: authManager)
            
            // 3. URLSession 설정
            let configuration = URLSessionConfiguration.default
            configuration.timeoutIntervalForRequest = 30
            configuration.timeoutIntervalForResource = 60
            configuration.waitsForConnectivity = false
            
            // 4. ServerTrustManager 설정 (모든 SSL 검증 무시 - 개발용)
            let serverTrustManager = ServerTrustManager(
                allHostsMustBeEvaluated: false,
                evaluators: [cameraIP: DisabledTrustEvaluator()]
            )
            
            // 5. Alamofire Session 생성
            let session = Session(
                configuration: configuration,
                interceptor: interceptor,
                serverTrustManager: serverTrustManager
            )
            
            // 6. Moya Provider 생성
            self.provider = MoyaProvider<ShootingTarget>(
                session: session,
                plugins: [NetworkLoggerPlugin(configuration: .init(logOptions: .verbose))]
            )
    
    func getISO() async throws -> SettingResponse {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.getISO) { result in
                switch result {
                    
                case let .success(response):
                    do {
                        let response = try self.jsonDecoder.decode(SettingResponse.self, from: response.data)
                        continuation.resume(returning: response)
                    } catch {
                        Log.network("Failure - get ISO()", error.localizedDescription)
                        continuation.resume(throwing: error)
                    }
                case let .failure(error):
                    Log.network("Failure - get ISO()", error.localizedDescription)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    func putISO(value: String) async throws -> SettingResponse {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.putISO(value)) { result in
                switch result {
                case let .success(response):
                    do {
                        let response = try self.jsonDecoder.decode(SettingResponse.self, from: response.data)
                    } catch {
                        Log.network("Failure - get ISO()", error.localizedDescription)
                        continuation.resume(throwing: error)
                    }
                case let .failure(error):
                    Log.network("Failure - get ISO()", error.localizedDescription)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
