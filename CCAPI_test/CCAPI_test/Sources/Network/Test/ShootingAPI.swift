//
//  CameraEndpoint.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import Foundation

enum ShootingAPI {
    case ISO
    
    var apiDesc: String {
        switch self {
        case .ISO:
            "ver100/shooting/settings/iso"
        }
    }
}
