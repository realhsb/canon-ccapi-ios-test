//
//  LiveTarget.swift
//  CCAPI_test
//
//  Created by Subeen on 10/15/25.
//

import Moya

enum LiveTarget {
    case startLiveView(LiveRequest)
    case stream
    case stopLiveView
}

extension LiveTarget: BaseTargetType {
    
    var path: String {
        switch self {
        case .startLiveView: return LiveAPI.stopLiveView.apiDesc
        case .stream: return LiveAPI.stream.apiDesc
        case .stopLiveView: return LiveAPI.stopLiveView.apiDesc
        }
    }
    var method: Moya.Method {
        switch self {
        case .startLiveView: return .post
        case .stream: return .get
        case .stopLiveView: return .delete
        }
    }
    var task: Task {
        switch self {
        case .startLiveView(let request):
//            let body: [String: Any] = ["liveviewsize": "small", "cameradisplay": "on"]
            return .requestJSONEncodable(request)
            
        case .stream:
            return .requestPlain
            
        case .stopLiveView:
            return .requestPlain
        }
    }
    
    var headers: [String : String]? {
        switch self {
        case .stream:
            return ["Accept" : "image/octet-stream"]
            
        default:
            return ["Content-Type" : "application/json"]
        }
    }
}
