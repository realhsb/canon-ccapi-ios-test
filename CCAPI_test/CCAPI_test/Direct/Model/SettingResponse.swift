//
//  SettingResponse.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import Foundation

/// Shooting setting value
/// - tv
/// - iso
/// 
struct SettingResponse: Codable {
    var value: String?
    var ability: [String]?
}
