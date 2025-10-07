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
    
    // MARK: - GET ISO
    
    /// ISO 값 조회
    /// - Returns: ISO 설정 응답
    func getISO() async throws -> SettingResponse {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.getISO) { result in
                switch result {
                case .success(let response):
                    do {
                        // 200-299 범위 확인
                        let filteredResponse = try response.filterSuccessfulStatusCodes()
                        let settingResponse = try self.jsonDecoder.decode(
                            SettingResponse.self,
                            from: filteredResponse.data
                        )
                        
                        print("ISO retrieved successfully")
                        print("  Value: \(settingResponse.value ?? "nil")")
                        print("  Ability: \(settingResponse.ability ?? [])")
                        
                        continuation.resume(returning: settingResponse)
                        
                    } catch MoyaError.statusCode(let response) {
                        print("API Error - Status: \(response.statusCode)")
                        //                        Log.network("Failure - get ISO()", "Status code: \(response.statusCode)")
                        continuation.resume(throwing: CCAPIError.unexpectedStatusCode(response.statusCode))
                        
                    } catch {
                        print("Decoding failed: \(error.localizedDescription)")
                        //                        Log.network("Failure - get ISO() - Decoding", error.localizedDescription)
                        continuation.resume(throwing: CCAPIError.decodingFailed(error.localizedDescription))
                    }
                    
                case .failure(let error):
                    print("Request failed: \(error.localizedDescription)")
                    Log.network("Failure - get ISO() - Request", error.localizedDescription)
                    continuation.resume(throwing: error)
                }
            }
        }
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
                        //                        Log.network("Failure - put ISO()", "Status code: \(response.statusCode)")
                        continuation.resume(throwing: CCAPIError.unexpectedStatusCode(response.statusCode))
                        
                    } catch {
                        print("Decoding failed: \(error.localizedDescription)")
                        //                        Log.network("Failure - put ISO() - Decoding", error.localizedDescription)
                        continuation.resume(throwing: CCAPIError.decodingFailed(error.localizedDescription))
                    }
                    
                case .failure(let error):
                    print("Request failed: \(error.localizedDescription)")
                    //                    Log.network("Failure - put ISO() - Request", error.localizedDescription)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
}
