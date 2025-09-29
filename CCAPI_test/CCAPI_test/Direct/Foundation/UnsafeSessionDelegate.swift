//
//  UnsafeSessionDelegate.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import Alamofire
import Foundation

final class UnsafeSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}


// 모든 호스트 신뢰 (개발용, unsafe)
let serverTrustManager = ServerTrustManager(allHostsMustBeEvaluated: false,
                                            evaluators: ["192.168.1.2": DisabledTrustEvaluator()])

let unsafeSession: Alamofire.Session = {
    let configuration = URLSessionConfiguration.default
    return Alamofire.Session(configuration: configuration,
                             serverTrustManager: serverTrustManager)
}()
