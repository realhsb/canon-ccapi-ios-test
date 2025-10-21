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
    case getColorTemperature
    case putColorTemperature(Int)
    case shoot(Bool)
}

extension ShootingTarget: BaseTargetType {
    var path: String {
        switch self {
        case .getISO, .putISO:
            return ShootingAPI.ISO.apiDesc
            
        case .getColorTemperature, .putColorTemperature:
            return ShootingAPI.ColorTemperature.apiDesc
            
        case .shoot:
            return ShootingAPI.shoot.apiDesc
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .getISO, .getColorTemperature:
                .get
        case .putISO(let value):
                .put
            
        case .putColorTemperature(let value):
                .put
        case .shoot(let af):
                .post
        }
    }
    
    var task: Moya.Task {
        switch self {
        case .getISO, .getColorTemperature:
            return .requestPlain
            
        case .putISO(let value):
            let parameters: [String : Any] = [
                "value" : value
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
            
        case .putColorTemperature(let value):
            let parameters: [String : Any] = [
                "value" : value
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
            
        case .shoot(let af):
            let parameters: [String : Any] = [
                "af" : af
            ]
            return .requestParameters(parameters: parameters, encoding: JSONEncoding.default)
        }
    }
}
