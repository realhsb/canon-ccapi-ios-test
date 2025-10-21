//
//  TestService.swift
//  CCAPI_test
//
//  Created by Subeen on 10/17/25.
//

import Combine
import CombineMoya
import Moya

protocol TestServiceType {
    /// ISO 값 조회
    func getISO() async throws -> SettingResponse
    
    /// ISO 값 변경
    func putISO(value: String) async throws -> SettingResponse
    
    
}

final class TestService: BaseService, TestServiceType {

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
