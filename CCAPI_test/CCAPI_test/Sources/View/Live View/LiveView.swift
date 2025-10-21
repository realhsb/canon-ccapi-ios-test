//
//  LiveView.swift
//  CCAPI_test
//
//  Created by Subeen on 10/15/25.
//

import SwiftUI

struct LiveView: View {
    
    @StateObject private var viewModel = LiveViewModel()
    
    var body: some View {
        VStack {
            if let image = viewModel.currentImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView("Connecting to Live View...")
            }
        }
        .task {
            await viewModel.start()
        }
        .onDisappear {
            Task { await viewModel.stop() }
        }
    }
}

#Preview {
    LiveView()
}
