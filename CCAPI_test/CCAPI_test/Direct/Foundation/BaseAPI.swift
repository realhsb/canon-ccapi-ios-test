//
//  BaseAPI.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import Foundation

public enum BaseAPI: String {
    case base
    
    public var apiDesc: String {
        switch self {
        case .base:
            return "https://192.168.1.2/ccapi/" // TODO: 카메라마다 API 주소 다름
        }
    }
}

