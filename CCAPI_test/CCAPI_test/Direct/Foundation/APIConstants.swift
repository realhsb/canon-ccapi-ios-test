//
//  APIConstants.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import Foundation

struct APIConstants{
    static let contentType = "Content-Type"
    
}

extension APIConstants {
    static var baseHeader: Dictionary<String, String> {
        [
            contentType : APIHeaderManager.shared.contentType
        ]
    }
}
