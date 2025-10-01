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
    var provider = MoyaProvider<ShootingTarget>(plugins: [MoyaLoggingPlugin()])
    
    let client = CCAPIClient()
    
    func getISO() async throws -> SettingResponse {
        return try await withCheckedThrowingContinuation { continuation in
            // 1단계: 인증
            client.authenticate(username: "soop", password: "0000") { result in
                switch result {
                case .success:
                    print("인증 성공!")
                    
                    // 2단계: API 호출
                    self.client.makeAuthenticatedRequest(endpoint: "ver100/shooting/settings/iso") { result in
                        switch result {
                        case .success(let data):
                            // 3단계: JSON 디코딩
                            do {
                                let decodedResponse = try self.jsonDecoder.decode(SettingResponse.self, from: data)
                                print("디코딩 성공: value=\(decodedResponse.value ?? "nil"), ability=\(decodedResponse.ability ?? [])")
                                continuation.resume(returning: decodedResponse)
                            } catch {
                                print("디코딩 실패: \(error.localizedDescription)")
                                Log.network("Failure - get ISO() - Decoding", error.localizedDescription)
                                continuation.resume(throwing: error)
                            }
                            
                        case .failure(let error):
                            print("API 호출 실패: \(error)")
                            Log.network("Failure - get ISO() - API Request", error.localizedDescription)
                            continuation.resume(throwing: error)
                        }
                    }
                    
                case .failure(let error):
                    print("인증 실패: \(error)")
                    Log.network("Failure - get ISO() - Authentication", error.localizedDescription)
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
                        let decodedResponse = try self.jsonDecoder.decode(SettingResponse.self, from: response.data)
                        continuation.resume(returning: decodedResponse)
                    } catch {
                        Log.network("Failure - put ISO() - Decoding", error.localizedDescription)
                        continuation.resume(throwing: error)
                    }
                case let .failure(error):
                    Log.network("Failure - put ISO()", error.localizedDescription)
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

