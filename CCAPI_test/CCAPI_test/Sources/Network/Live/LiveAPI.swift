//
//  LiveAPI.swift
//  CCAPI_test
//
//  Created by Subeen on 10/15/25.
//

import Foundation

enum LiveAPI {
    case startLiveView
    case stream
    case stopLiveView
    
    var apiDesc: String {
        switch self {
        case .startLiveView:
            return "ver100/shooting/liveview"
        case .stream:
            return "ver100/shooting/liveview/scroll"
        case .stopLiveView:
            return "ver100/shooting/liveview/scroll"
        }
    }
}

