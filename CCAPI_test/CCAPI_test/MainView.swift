//
//  MainView.swift
//  CCAPI_test
//
//  Created by Subeen on 10/15/25.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationStack {
            VStack {
                NavigationLink("Camera Control") {
                    CameraDirectControlView()
                }
                
//                NavigationLink("Live View") {
//                    LiveView()
//                }
            }
        }
    }
}

#Preview {
    MainView()
}
