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

protocol ShootingServiceType {
    func getISO() async throws -> SettingResponse
    func putISO(value: String) async throws -> SettingResponse
}

final class ShootingService: ShootingServiceType {
    
    private let jsonDecoder = JSONDecoder()
//    let provider = MoyaProvider<ShootingTarget>(plugins: [MoyaLoggingPlugin()])
    let provider = MoyaProvider<ShootingTarget>(
        session: unsafeSession,
        plugins: [MoyaLoggingPlugin()]
    )
    
    func getISO() async throws -> SettingResponse {
        return try await withCheckedThrowingContinuation { continuation in
            provider.request(.getISO) { result in
                switch result {
                    
                case let .success(response):
                    do {
                        let response = try self.jsonDecoder.decode(SettingResponse.self, from: response.data)
//
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
