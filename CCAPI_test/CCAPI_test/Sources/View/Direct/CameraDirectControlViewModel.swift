//
//  CameraDirectControlViewModel.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import SwiftUI

@Observable
final class CameraDirectControlViewModel {
    
    var currentISO: String = "none"
    var currentAbility: [String] = []
    var settingResponse: SettingResponse?
    
    let shootingService = ShootingService()
}

extension CameraDirectControlViewModel {
    func getISO() async {
        do {
            settingResponse = try await shootingService.getISO()
            currentISO = settingResponse?.value ?? "get error"
            currentAbility = settingResponse?.ability ?? []
        } catch {
            print("vm error - get ISO")
        }
    }
    
    func setISO(value: String) async {
        do {
            settingResponse = try await shootingService.putISO(value: value)
            currentISO = settingResponse?.value ?? "set error"
        } catch {
            print("vm error - set ISO")
        }
    }
}
