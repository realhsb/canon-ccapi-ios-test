//
//  ShootingTarget.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import Foundation
import Moya

enum ShootingTarget {
    case getISO
    case putISO(String)
}

extension ShootingTarget: BaseTargetType {
    var path: String {
        switch self {
        case .getISO, .putISO:
            return ShootingAPI.ISO.apiDesc
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getISO:
                .get
        case .putISO(let string):
                .put
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .getISO:
            return .requestPlain
            
        case .putISO(let value):
            let parameters: [String : Any] = [
                "value" : value
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        }
    }
}
