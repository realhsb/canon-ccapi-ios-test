//
//  Models.swift
//  CCAPI_test
//
//  Created by Subeen on 9/27/25.
//

import Foundation
import Network
import SwiftUI

// MARK: - Models

struct CanonCamera: Identifiable, Codable {
    let id = UUID()
    let friendlyName: String
    let modelName: String
    let serialNumber: String
    let udn: String
    let ccapiURL: String
    let ipAddress: String
    
    var displayName: String {
        return friendlyName.isEmpty ? modelName : friendlyName
    }
}

struct DeviceDescriptionResponse {
    let friendlyName: String
    let modelName: String
    let serialNumber: String
    let udn: String
    let ccapiURL: String
}
