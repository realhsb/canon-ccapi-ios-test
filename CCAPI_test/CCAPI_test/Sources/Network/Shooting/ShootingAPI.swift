//
//  CameraEndpoint.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import Foundation

enum ShootingAPI {
    case ISO
    case ColorTemperature
    case shoot
    
    var apiDesc: String {
        switch self {
        case .ISO:
            "ver100/shooting/settings/iso"
            
        case .ColorTemperature:
            "ver100/shooting/settings/colortemperature"
            
        case .shoot:
            "ver100/shooting/control/shutterbutton"
        }
    }
}
