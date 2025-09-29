//
//  CameraDirectControlView.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import SwiftUI

struct CameraDirectControlView: View {
    
    @State var viewModel: CameraDirectControlViewModel = .init()
    
    var body: some View {
        VStack {
            Text(viewModel.currentISO)
            
            Button("refresh") {
                Task {
                    await viewModel.getISO()
                }
            }
            
            HStack {
                ForEach(viewModel.currentAbility, id: \.self) { ability in
                    Button(ability) {
                        Task {
                            await viewModel.setISO(value: ability)
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                await viewModel.getISO()
            }
        }
    }
}

#Preview {
    CameraDirectControlView()
}
