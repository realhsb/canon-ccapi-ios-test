//
//  TestView.swift
//  CCAPI_test
//
//  Created by Subeen on 10/17/25.
//

import SwiftUI

struct TestView: View {
    
    @State var viewModel: CameraDirectControlViewModel = .init()
    
    var body: some View {
        VStack(spacing: 20) {
            Button {
                Task {
                    await viewModel.setISO(value: "400")
                    await viewModel.setColorTemperature(value: 3200)
                    await viewModel.shooting(value: true)
                    // TODO
                }
                
            } label: {
                VStack {
                    Text("Preset 1")
                    Text("ISO 400")
                    Text("3200K")
                }
            }
            
            Button {
                Task {
                    await viewModel.setISO(value: "1600")
                    await viewModel.setColorTemperature(value: 4000)
                    await viewModel.shooting(value: true)
                }
            } label: {
                Text("Preset 2")
                Text("ISO 1600")
                Text("4000K")
            }
            
            Button {
                Task {
                    await viewModel.setISO(value: "3000")
                    await viewModel.setColorTemperature(value: 5000)
                    await viewModel.shooting(value: true)
                }
            } label: {
                Text("Preset 3")
                Text("ISO 3000")
                Text("5000K")
            }
            
            Button {
                Task {
                    await viewModel.shooting(value: true)
                }
            } label: {
                Text("Shoot")
            }
        }
    }
}

#Preview {
    TestView()
}
