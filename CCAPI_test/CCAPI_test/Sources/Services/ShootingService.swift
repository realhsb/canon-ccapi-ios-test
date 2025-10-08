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

/// Shooting 관련 API 서비스 프로토콜
protocol ShootingServiceType {
    /// ISO 값 조회
    func getISO() async throws -> SettingResponse
    
    /// ISO 값 변경
    func putISO(value: String) async throws -> SettingResponse
}

/// Shooting 관련 API 서비스 구현 (Moya 사용)
final class ShootingService: ShootingServiceType {
    
    private let jsonDecoder = JSONDecoder()
    private let provider = NetworkManager.shared.ccapiProvider
    private let authPlugin = NetworkManager.shared.digestAuthPlugin  // ✨ Plugin 참조
    
    private var isAuthInitialized = false
    
    // MARK: - GET ISO
    
    /// ISO 값 조회
    /// - Returns: ISO 설정 응답
    func getISO() async throws -> SettingResponse {
        // ✨ 첫 호출 시 인증 초기화
        if !isAuthInitialized {
            try await authPlugin.initializeAuth()
            isAuthInitialized = true
        }
        
        var retryCount = 0
        let maxRetries = 3
        
        while retryCount <= maxRetries {
            let result = await withCheckedContinuation { (continuation: CheckedContinuation<Result<SettingResponse, Error>, Never>) in
                provider.request(.getISO) { result in
                    switch result {
                    case .success(let response):
                        // 401 체크
                        if response.statusCode == 401 && retryCount < maxRetries {
                            print("⚠️  Received 401, will retry (\(retryCount + 1)/\(maxRetries))")
                            continuation.resume(returning: .failure(CCAPIError.authenticationFailed(401)))
                            return
                        }
                        
                        do {
                            let filteredResponse = try response.filterSuccessfulStatusCodes()
                            let settingResponse = try self.jsonDecoder.decode(
                                SettingResponse.self,
                                from: filteredResponse.data
                            )
                            
                            print("✅ ISO retrieved successfully")
                            print("  Value: \(settingResponse.value ?? "nil")")
                            print("  Ability: \(settingResponse.ability ?? [])")
                            
                            continuation.resume(returning: .success(settingResponse))
                            
                        } catch MoyaError.statusCode(let response) {
                            print("❌ API Error - Status: \(response.statusCode)")
                            Log.network("Failure - get ISO()", "Status code: \(response.statusCode)")
                            continuation.resume(returning: .failure(CCAPIError.unexpectedStatusCode(response.statusCode)))
                            
                        } catch {
                            print("❌ Decoding failed: \(error.localizedDescription)")
                            Log.network("Failure - get ISO() - Decoding", error.localizedDescription)
                            continuation.resume(returning: .failure(CCAPIError.decodingFailed(error.localizedDescription)))
                        }
                        
                    case .failure(let error):
                        print("❌ Request failed: \(error.localizedDescription)")
                        Log.network("Failure - get ISO() - Request", error.localizedDescription)
                        continuation.resume(returning: .failure(error))
                    }
                }
            }
            
            // 결과 확인
            switch result {
            case .success(let response):
                return response  // 성공 - 반환
            
                // TODO: error 처리
            case .failure(let error):
                if let ccapiError = error as? CCAPIError,
                   case .authenticationFailed = ccapiError {
                    // 401 에러 - 재시도
                    retryCount += 1
//                    try? await Task.sleep(nanoseconds: 500_000_000)  // 0.5초 대기
                    continue
                } else {
                    // 다른 에러 - 바로 throw
                    throw error
                }
            }
        }
        
        throw CCAPIError.maxRetriesExceeded
    }
    
    // MARK: - PUT ISO
    
    /// ISO 값 변경
    /// - Parameter value: 변경할 ISO 값 (예: "100", "200", "auto")
    /// - Returns: 변경된 ISO 설정 응답
    func putISO(value: String) async throws -> SettingResponse {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.putISO(value)) { result in
                switch result {
                case .success(let response):
                    do {
                        let filteredResponse = try response.filterSuccessfulStatusCodes()
                        let settingResponse = try self.jsonDecoder.decode(
                            SettingResponse.self,
                            from: filteredResponse.data
                        )
                        
                        print("ISO updated successfully")
                        print("  New value: \(settingResponse.value ?? "nil")")
                        
                        continuation.resume(returning: settingResponse)
                        
                    } catch MoyaError.statusCode(let response) {
                        print("API Error - Status: \(response.statusCode)")
                        Log.network("Failure - put ISO()", "Status code: \(response.statusCode)")
                        continuation.resume(throwing: CCAPIError.unexpectedStatusCode(response.statusCode))
                        
                    } catch {
                        print("Decoding failed: \(error.localizedDescription)")
                        Log.network("Failure - put ISO() - Decoding", error.localizedDescription)
                        continuation.resume(throwing: CCAPIError.decodingFailed(error.localizedDescription))
                    }
                    
                case .failure(let error):
                    print("Request failed: \(error.localizedDescription)")
                    Log.network("Failure - put ISO() - Request", error.localizedDescription)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
