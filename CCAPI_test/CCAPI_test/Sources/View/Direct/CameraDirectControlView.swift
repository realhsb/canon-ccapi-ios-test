//
//  CameraDirectControlView.swift
//  CCAPI_test
//
//  Created by Subeen on 9/29/25.
//

import SwiftUI

struct CameraDirectControlView: View {
    
    @State var viewModel: CameraDirectControlViewModel = .init()
    @State var currentIndex: Int = 0
    
    var body: some View {
        VStack {
            Text(viewModel.currentISO)
            
            Button("refresh") {
                Task {
                    await viewModel.getISO()
                    
                }
            }
            
            HStack(spacing: 20) {
                Button("-") {
                    if currentIndex > 0 {
                        currentIndex -= 1
                        Task {
                            await viewModel.setISO(value: viewModel.currentISOAbility[currentIndex])
                        }
                    }
                }
                .disabled(currentIndex == 0)
                
                Text(viewModel.currentISOAbility.isEmpty ? "" : viewModel.currentISOAbility[currentIndex])
                    .frame(minWidth: 100)
                
                Button("+") {
                    if currentIndex < viewModel.currentISOAbility.count - 1 {
                        currentIndex += 1
                        Task {
                            await viewModel.setISO(value: viewModel.currentISOAbility[currentIndex])
                        }
                    }
                }
                .disabled(currentIndex == viewModel.currentISOAbility.count - 1)
            }
            
            
//            LazyHGrid {
//                ForEach(viewModel.currentISOAbility, id: \.self) { ability in
//
//                    Button {
//                        
//                    } label: {
//                        Text(ability)
//                    }
//                    Button(ability) {
//                        Task {
//                            await viewModel.setISO(value: ability)
//                        }
//                    }
//                }
//            }
//            
            
        }
    }
}

#Preview {
    CameraDirectControlView()
}
