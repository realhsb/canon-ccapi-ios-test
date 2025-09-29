//
//  BaseTargetType.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import Foundation
import Moya

protocol BaseTargetType: TargetType {}


extension BaseTargetType {
    public var baseURL: URL {
        return URL(string: BaseAPI.base.apiDesc)!
    }
    
    public var headers: [String : String]? {
        return APIConstants.baseHeader
    }
    
}
