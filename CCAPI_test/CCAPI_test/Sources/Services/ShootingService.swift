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
final class ShootingService: BaseService, ShootingServiceType {
    
//    private let jsonDecoder = JSONDecoder()
//    private let provider = NetworkManager.shared.ccapiProvider
//    private let authPlugin = NetworkManager.shared.digestAuthPlugin  // ✨ Plugin 참조
    
    private var isAuthInitialized = false
    
    // MARK: - GET ISO
    
    /// ISO 값 조회
    /// - Returns: ISO 설정 응답
    func getISO() async throws -> SettingResponse {
        let response = try await requestWithRetry(ShootingTarget.getISO, decoding: SettingResponse.self)
        
        print("✅ ISO retrieved successfully")
        print("  Value: \(response.value ?? "nil")")
        print("  Ability: \(response.ability ?? [])")
        
        return response
    }
    
    /// ISO 값 변경

    
    // MARK: - PUT ISO
    
    /// ISO 값 변경
    /// - Parameter value: 변경할 ISO 값 (예: "100", "200", "auto")
    /// - Returns: 변경된 ISO 설정 응답
    func putISO(value: String) async throws -> SettingResponse {
        let response = try await requestWithRetry(ShootingTarget.putISO(value), decoding: SettingResponse.self)
        
        print("✅ ISO updated successfully")
        print("  New value: \(response.value ?? "nil")")
        
        return response
    }
}
