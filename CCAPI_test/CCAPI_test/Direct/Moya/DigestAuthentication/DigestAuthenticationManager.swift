//
//  DigestAuthenticationManager.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import Foundation
import Moya
import Alamofire
import CryptoKit

// MARK: - Digest Authentication Manager
/// Digest 인증 정보를 관리하고 인증 헤더를 생성하는 클래스
class DigestAuthenticationManager {
    private var username: String
    private var password: String
    private var cachedDigestInfo: DigestInfo?
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    /// 서버로부터 받은 Digest 인증 정보
    struct DigestInfo {
        let realm: String       // 인증 영역 (예: "camera")
        let nonce: String       // 서버가 생성한 일회용 값
        let qop: String?        // 인증 품질 (보통 "auth")
        let opaque: String?     // 서버가 반환할 불투명한 데이터
        let algorithm: String   // 해시 알고리즘 (보통 "MD5")
        var nc: Int = 1         // 요청 카운터 (nonce count)
        
        mutating func incrementNc() {
            nc += 1
        }
    }
    
    // MARK: - WWW-Authenticate 헤더 파싱
    /// 서버의 401 응답에서 Digest challenge를 파싱합니다
    /// - Parameter header: "Digest realm="camera", nonce="abc123", ..." 형태의 문자열
    /// - Returns: 파싱된 DigestInfo 또는 nil
    func parseDigestChallenge(from header: String) -> DigestInfo? {
        // "Digest " 접두사 제거
        let components = header.replacingOccurrences(of: "Digest ", with: "")
            .components(separatedBy: ", ")
        
        var params: [String: String] = [:]
        
        for component in components {
            let keyValue = component.components(separatedBy: "=")
            if keyValue.count == 2 {
                let key = keyValue[0].trimmingCharacters(in: .whitespaces)
                let value = keyValue[1].trimmingCharacters(in: .init(charactersIn: "\" "))
                params[key] = value
            }
        }
        
        guard let realm = params["realm"],
              let nonce = params["nonce"] else {
            return nil
        }
        
        return DigestInfo(
            realm: realm,
            nonce: nonce,
            qop: params["qop"],
            opaque: params["opaque"],
            algorithm: params["algorithm"] ?? "MD5",
            nc: 1
        )
    }
    
    // MARK: - Authorization 헤더 생성
    /// Digest 인증을 위한 Authorization 헤더를 생성합니다
    /// - Parameters:
    ///   - digestInfo: 서버로부터 받은 Digest 정보
    ///   - method: HTTP 메서드 (GET, PUT, POST 등)
    ///   - uri: 요청 URI path
    /// - Returns: "Digest username="...", realm="...", ..." 형태의 헤더 문자열
    func createAuthorizationHeader(
        digestInfo: DigestInfo,
        method: String,
        uri: String
    ) -> String {
        // URI가 baseURL을 포함하지 않도록 주의
        // /ccapi/ver100/... 형태여야 함
        let cleanUri = uri.hasPrefix("/") ? uri : "/" + uri
        
        let ha1 = md5("\(username):\(digestInfo.realm):\(password)")
        let ha2 = md5("\(method):\(cleanUri)")
        
        let cnonce = generateCnonce()
        let ncValue = String(format: "%08x", digestInfo.nc)
        
        let response: String
        if let qop = digestInfo.qop {
            response = md5("\(ha1):\(digestInfo.nonce):\(ncValue):\(cnonce):\(qop):\(ha2)")
        } else {
            response = md5("\(ha1):\(digestInfo.nonce):\(ha2)")
        }
        
        var header = "Digest username=\"\(username)\", realm=\"\(digestInfo.realm)\", nonce=\"\(digestInfo.nonce)\", uri=\"\(cleanUri)\", response=\"\(response)\""
        
        if let qop = digestInfo.qop {
            header += ", qop=\(qop), nc=\(ncValue), cnonce=\"\(cnonce)\""
        }
        
        if let opaque = digestInfo.opaque {
            header += ", opaque=\"\(opaque)\""
        }
        
        header += ", algorithm=\(digestInfo.algorithm)"
        
        return header
    }
//    func createAuthorizationHeader(
//        digestInfo: DigestInfo,
//        method: String,
//        uri: String
//    ) -> String {
//        // HA1 = MD5(username:realm:password)
//        let ha1 = md5("\(username):\(digestInfo.realm):\(password)")
//        
//        // HA2 = MD5(method:uri)
//        let ha2 = md5("\(method):\(uri)")
//        
//        // cnonce: 클라이언트가 생성하는 랜덤 값
//        let cnonce = generateCnonce()
//        
//        // nc: nonce count를 16진수 8자리로 변환
//        let ncValue = String(format: "%08x", digestInfo.nc)
//        
//        // response 계산
//        let response: String
//        if let qop = digestInfo.qop {
//            // qop가 있는 경우: MD5(HA1:nonce:nc:cnonce:qop:HA2)
//            response = md5("\(ha1):\(digestInfo.nonce):\(ncValue):\(cnonce):\(qop):\(ha2)")
//        } else {
//            // qop가 없는 경우: MD5(HA1:nonce:HA2)
//            response = md5("\(ha1):\(digestInfo.nonce):\(ha2)")
//        }
//        
//        // Authorization 헤더 조합
//        var header = "Digest username=\"\(username)\", realm=\"\(digestInfo.realm)\", nonce=\"\(digestInfo.nonce)\", uri=\"\(uri)\", response=\"\(response)\""
//        
//        if let qop = digestInfo.qop {
//            header += ", qop=\(qop), nc=\(ncValue), cnonce=\"\(cnonce)\""
//        }
//        
//        if let opaque = digestInfo.opaque {
//            header += ", opaque=\"\(opaque)\""
//        }
//        
//        header += ", algorithm=\(digestInfo.algorithm)"
//        
//        return header
//    }
    
    // MARK: - Initial Challenge Fetching
    /// 초기 Digest challenge를 가져옵니다
    func fetchInitialChallenge(from url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 401,
              let wwwAuthHeader = httpResponse.value(forHTTPHeaderField: "WWW-Authenticate"),
              let digestInfo = parseDigestChallenge(from: wwwAuthHeader) else {
            throw NSError(domain: "DigestAuth", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch initial challenge"])
        }
        
        print("✅ Initial digest challenge fetched successfully")
        print("Realm: \(digestInfo.realm)")
        print("Nonce: \(digestInfo.nonce)")
        
        updateDigestInfo(digestInfo)
    }
    
    // MARK: - Helper Methods
    
    /// MD5 해시를 계산합니다
    private func md5(_ string: String) -> String {
        let digest = Insecure.MD5.hash(data: Data(string.utf8))
        return digest.map { String(format: "%02hhx", $0) }.joined()
    }
    
    /// 클라이언트 nonce(cnonce)를 생성합니다
    private func generateCnonce() -> String {
        // UUID 사용 (가장 권장되는 방법)
        return UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
    }
    
    /// Digest 정보를 캐시에 저장합니다
    func updateDigestInfo(_ info: DigestInfo) {
        cachedDigestInfo = info
    }
    
    /// 캐시된 Digest 정보를 가져옵니다
    func getCachedDigestInfo() -> DigestInfo? {
        return cachedDigestInfo
    }
}
