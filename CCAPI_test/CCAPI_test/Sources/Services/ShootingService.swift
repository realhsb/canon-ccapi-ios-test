//
//  CameraService.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import Combine
import CombineMoya
import Moya

protocol ShootingServiceType {
    /// ISO 값 조회
    func getISO() async throws -> SettingResponse
    
    /// ISO 값 변경
    func putISO(value: String) async throws -> SettingResponse
    
    func getColorTemperature() async throws -> ColorTemperatureResponse
    func putColorTemperature(value: Int) async throws -> ColorTemperatureResponse
    func shoot(af: Bool) async throws -> SettingResponse
}

final class ShootingService: BaseService, ShootingServiceType {

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
    
    /// 색온도 조회
    func getColorTemperature() async throws -> ColorTemperatureResponse {
        let response = try await requestWithRetry(ShootingTarget.getColorTemperature, decoding: ColorTemperatureResponse.self)
        
        return response
    }
    
    /// 색온도 값 변경
    func putColorTemperature(value: Int) async throws -> ColorTemperatureResponse {
        let response = try await requestWithRetry(ShootingTarget.putColorTemperature(value), decoding: ColorTemperatureResponse.self)
        
        return response
    }
    
    func shoot(af: Bool) async throws -> SettingResponse {
        let response = try await requestWithRetry(ShootingTarget.shoot(af), decoding: SettingResponse.self)
        
        print("success")
        
        return response 
    }
}
