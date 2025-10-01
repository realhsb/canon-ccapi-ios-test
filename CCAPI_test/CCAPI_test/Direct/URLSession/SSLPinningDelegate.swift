//
//  SSLPinningDelegate.swift
//  CCAPI_test
//
//  Created by Subeen on 10/1/25.
//

import Foundation

// SSL 인증서 처리를 위한 Delegate (자체 서명 인증서용)
class SSLPinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        print("🔐 Received authentication challenge")
        print("   Protection space: \(challenge.protectionSpace.authenticationMethod)")
        print("   Host: \(challenge.protectionSpace.host)")
        
        // 개발 환경에서 자체 서명 인증서 허용
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                print("✅ Accepting self-signed certificate")
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }
        
        print("⚠️  Using default handling")
        completionHandler(.performDefaultHandling, nil)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("❌ URLSession task completed with error: \(error.localizedDescription)")
        }
    }
}
