//
//  CameraService.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import Foundation
//import Combine
//import CombineMoya
//import Moya
import SwiftUI
import Alamofire

/// Shooting 관련 API 서비스 프로토콜
protocol ShootingServiceType {
    /// ISO 값 조회
    func getISO() async throws -> SettingResponse
    
    /// ISO 값 변경
    func putISO(value: String) async throws -> SettingResponse
}

/// Shooting 관련 API 서비스 구현
final class ShootingService: ShootingServiceType {
    
    private let jsonDecoder = JSONDecoder()
//    var provider = MoyaProvider<ShootingTarget>(plugins: [MoyaLoggingPlugin()])
    
    // CCAPIClient 싱글톤 사용
    let client = CCAPIClient.shared
    
    // 인증 정보
    private let username = "soop"
    private let password = "0000"
    private var isClientAuthenticated = false
    
    // MARK: - GET ISO
    
    /// ISO 값 조회
    /// - Returns: ISO 설정 응답
    func getISO() async throws -> SettingResponse {
        // 첫 호출 시에만 인증
        if !isClientAuthenticated {
            do {
                try await client.authenticate(username: username, password: password)
                isClientAuthenticated = true
                print("Client authenticated successfully")
            } catch {
                print("Authentication failed: \(error.localizedDescription)")
                Log.network("Failure - get ISO() - Authentication", error.localizedDescription)
                throw error
            }
        }
        
        // API 호출
        do {
            let data = try await client.makeRequest(endpoint: "ver100/shooting/settings/iso")
            let response = try jsonDecoder.decode(SettingResponse.self, from: data)
            
            print("ISO retrieved successfully")
            print("  Value: \(response.value ?? "nil")")
            print("  Ability: \(response.ability ?? [])")
            
            return response
            
        } catch let error as CCAPIError {
            print("API request failed: \(error.localizedDescription)")
            Log.network("Failure - get ISO()", error.localizedDescription)
            throw error
            
        } catch {
            print("Decoding failed: \(error.localizedDescription)")
            Log.network("Failure - get ISO() - Decoding", error.localizedDescription)
            throw CCAPIError.decodingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - PUT ISO
    
    /// ISO 값 변경
    /// - Parameter value: 변경할 ISO 값 (예: "100", "200", "auto")
    /// - Returns: 변경된 ISO 설정 응답
    func putISO(value: String) async throws -> SettingResponse {
        // 인증 확인
        if !isClientAuthenticated {
            try await client.authenticate(username: username, password: password)
            isClientAuthenticated = true
        }
        
        // JSON Body 생성
        let bodyDict = ["value": value]
        let bodyData = try JSONEncoder().encode(bodyDict)
        
        // API 호출
        do {
            let data = try await client.makeRequest(
                endpoint: "ver100/shooting/settings/iso",
                method: "PUT",
                body: bodyData
            )
            let response = try jsonDecoder.decode(SettingResponse.self, from: data)
            
            print("ISO updated successfully")
            print("  New value: \(response.value ?? "nil")")
            
            return response
            
        } catch let error as CCAPIError {
            print("PUT ISO failed: \(error.localizedDescription)")
            Log.network("Failure - put ISO()", error.localizedDescription)
            throw error
            
        } catch {
            print("Decoding failed: \(error.localizedDescription)")
            Log.network("Failure - put ISO() - Decoding", error.localizedDescription)
            throw CCAPIError.decodingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    /// 연결 테스트
    func testConnection() async {
        print("Starting connection test...")
        
        do {
            let response = try await getISO()
            print("Connection test successful!")
            print("  ISO: \(response.value ?? "unknown")")
        } catch {
            print("Connection test failed: \(error)")
        }
    }
    
    /// 인증 상태 리셋
    func resetAuthentication() {
        isClientAuthenticated = false
        client.resetAuthentication()
        print("Service authentication reset")
    }
}

// MARK: - Log Helper

///// 로그 출력 헬퍼 (기존 프로젝트에 Log 클래스가 있는 경우 사용)
//struct Log {
//    static func network(_ function: String, _ message: String) {
//        print("[Network] \(function): \(message)")
//    }
//}
