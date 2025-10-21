//
//  LiveService.swift
//  CCAPI_test
//
//  Created by Subeen on 10/15/25.
//

import Combine
import CombineMoya
import Moya
import Foundation
import SwiftUI

protocol LiveServiceType {
    func startLiveView() async throws -> Void
    func startStream() async throws -> Void
    func stopLiveView() async throws -> Void
}

final class LiveViewStreamService: BaseService, LiveServiceType {
    
    // URLSession with SSL delegate for streaming
    private lazy var streamSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 300
        
        // BaseService의 SSLPinningDelegate 재사용
        let delegate = SSLPinningDelegate()
        return URLSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
    }()
    
    // MARK: - 1️⃣ Live View 시작 요청
    func startLiveView() async throws {
        let body = LiveRequest(liveviewsize: "small", cameradisplay: "on")
        
        do {
            try await requestWithoutResponse(LiveTarget.startLiveView(body))
            print("✅ Live View started successfully")
        } catch {
            if case CCAPIError.unexpectedStatusCode(404) = error {
                print("❌ Live View API not found (404)")
                print("   Please check if camera supports live view")
                print("   Or try different API version (ver100, ver110, etc.)")
            }
            throw error
        }
    }

    // MARK: - 2️⃣ Chunked 스트리밍 수신
    func startStream() async throws {
        // 인증 확인 (BaseService의 메서드 사용)
        try await ensureAuthenticated()
        
        let target = LiveTarget.stream
        
        // URLRequest 생성
        var request = try target.asURLRequest()
        
        // CCAPIClient를 통해 Digest 인증 헤더 추가
        if let url = request.url?.absoluteString,
           let method = request.httpMethod {
            
            let authHeader = CCAPIClient.shared.getAuthHeader(
                method: method,
                url: url,
                body: request.httpBody
            )
            
            if let authHeader = authHeader {
                request.setValue(authHeader, forHTTPHeaderField: "Authorization")
                print("📋 Digest auth header added to stream request")
            } else {
                print("⚠️ Failed to generate auth header for stream")
                // 인증 헤더가 없어도 시도 (카메라가 인증을 요구하지 않을 수도 있음)
            }
        }
        
        // Accept 헤더 명시적 추가
        request.setValue("image/octet-stream", forHTTPHeaderField: "Accept")
        
        print("🔗 Connecting to stream: \(request.url?.absoluteString ?? "unknown")")
        
        // 커스텀 URLSession 사용 (SSL 인증서 무시)
        do {
            let (stream, response) = try await streamSession.bytes(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw CCAPIError.invalidResponse
            }
            
            print("📡 Stream response: \(httpResponse.statusCode)")
            
            switch httpResponse.statusCode {
            case 200:
                print("📸 Live View stream connected successfully")
                
                // 스트림 처리
                var byteCount = 0
                for try await byte in stream {
                    processChunkedByte(byte)
                    byteCount += 1
                    
                    // 진행 상황 로깅 (디버깅용)
                    if byteCount % 10000 == 0 {
                        print("   Streaming... \(byteCount) bytes received")
                    }
                }
                
            case 401:
                print("❌ Stream authentication failed (401)")
                throw CCAPIError.authenticationFailed(401)
                
            case 404:
                print("❌ Stream endpoint not found (404)")
                throw CCAPIError.unexpectedStatusCode(404)
                
            default:
                print("❌ Stream failed with status: \(httpResponse.statusCode)")
                throw CCAPIError.unexpectedStatusCode(httpResponse.statusCode)
            }
            
        } catch {
            print("❌ Stream error: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - 3️⃣ Live View 중지
    func stopLiveView() async throws {
        do {
            try await requestWithoutResponse(LiveTarget.stopLiveView)
            print("🛑 Live View stopped successfully")
            
            // 버퍼 클리어
            imageBuffer.removeAll(keepingCapacity: false)
            
        } catch {
            if case CCAPIError.unexpectedStatusCode(404) = error {
                print("ℹ️ Live View already stopped or not started")
                // 404는 무시 (이미 중지된 상태)
            } else {
                throw error
            }
        }
    }
    
    // MARK: - Private - JPEG 처리 로직
    private var imageBuffer = Data()
    private let jpegStartMarker: [UInt8] = [0xFF, 0xD8]  // JPEG SOI (Start of Image)
    private let jpegEndMarker: [UInt8] = [0xFF, 0xD9]    // JPEG EOI (End of Image)
    private var isCollectingFrame = false
    private var frameCount = 0

    private func processChunkedByte(_ byte: UInt8) {
        // JPEG 시작 마커 검출
        if !isCollectingFrame {
            imageBuffer.append(byte)
            
            // 버퍼가 2바이트 이상이고 시작 마커인지 확인
            if imageBuffer.count >= 2 {
                if imageBuffer.suffix(2) == Data(jpegStartMarker) {
                    // JPEG 프레임 수집 시작
                    isCollectingFrame = true
                    imageBuffer = Data(jpegStartMarker)  // 시작 마커만 유지
                    print("🎬 JPEG frame start detected")
                } else if imageBuffer.count > 2 {
                    // 시작 마커가 아니면 첫 바이트 제거 (슬라이딩 윈도우)
                    imageBuffer.removeFirst()
                }
            }
            return
        }
        
        // JPEG 데이터 수집 중
        imageBuffer.append(byte)
        
        // JPEG 종료 마커 검출
        if imageBuffer.count >= 4 && imageBuffer.suffix(2) == Data(jpegEndMarker) {
            // 완성된 JPEG 프레임 처리
            frameCount += 1
            print("📷 JPEG frame #\(frameCount) completed: \(imageBuffer.count) bytes")
            
            if let image = UIImage(data: imageBuffer) {
                // UI 업데이트는 메인 스레드에서
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .didReceiveLiveViewImage,
                        object: image
                    )
                }
                print("✅ Frame #\(frameCount) decoded successfully")
            } else {
                print("⚠️ Frame #\(frameCount) decode failed")
            }
            
            // 다음 프레임 준비
            imageBuffer.removeAll(keepingCapacity: true)
            isCollectingFrame = false
        }
        
        // 버퍼 오버플로우 방지 (5MB 제한)
        if imageBuffer.count > 5_000_000 {
            print("⚠️ Buffer overflow, resetting...")
            imageBuffer.removeAll(keepingCapacity: true)
            isCollectingFrame = false
        }
    }
}
