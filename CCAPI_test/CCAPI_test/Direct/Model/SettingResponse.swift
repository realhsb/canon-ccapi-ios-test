//
//  SettingResponse.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import Foundation

/// Shooting setting value 응답 모델
/// ISO, Tv(셔터스피드) 등의 카메라 설정 값 조회/변경 시 사용
struct SettingResponse: Codable {
    /// 현재 설정 값
    var value: String?
    
    /// 사용 가능한 설정 값 목록
    var ability: [String]?
}
