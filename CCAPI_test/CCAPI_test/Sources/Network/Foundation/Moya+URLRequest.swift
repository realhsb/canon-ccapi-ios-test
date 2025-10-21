//
//  Moya+URLRequest.swift
//  CCAPI_test
//
//  Created by Subeen on 10/16/25.
//

import Moya
import Foundation

extension TargetType {
    func asURLRequest() throws -> URLRequest {
        let endpoint = MoyaProvider<MultiTarget>.defaultEndpointMapping(for: MultiTarget(self))
        return try endpoint.urlRequest()
    }
}
