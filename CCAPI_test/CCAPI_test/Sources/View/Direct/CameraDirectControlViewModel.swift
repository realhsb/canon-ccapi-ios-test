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
    var currentColor: String = "0"
    var currentISOAbility: [String] = []
    var settingResponse: SettingResponse?
    var colorResponse: ColorTemperatureResponse?
    
    let shootingService = ShootingService()
}

extension CameraDirectControlViewModel {
    func getISO() async {
        do {
            settingResponse = try await shootingService.getISO()
            currentISO = settingResponse?.value ?? "get error"
            currentISOAbility = settingResponse?.ability ?? []
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
    
    func getColorTemperature() async {
        do {
            colorResponse = try await shootingService.getColorTemperature()
            currentColor = colorResponse?.value ?? "get error"
        } catch {
            print("vm error - get color temperature")
        }
    }
    
    func setColorTemperature(value: Int) async {
        do {
            colorResponse = try await shootingService.putColorTemperature(value: value)
            currentISO = colorResponse?.value ?? "set error"
        } catch {
            print("vm error - set color temperature")
        }
    }
    
    func shooting(value: Bool) async {
        do {
            try await shootingService.shoot(af: value)
        } catch {
            print("shoot error")
        }
    }
}
