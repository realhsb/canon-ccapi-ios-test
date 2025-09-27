//
//  CameraDiscoveryView.swift
//  CCAPI_test
//
//  Created by Subeen on 9/27/25.
//

import SwiftUI

struct CameraDiscoveryView: View {
    @StateObject private var discovery = CanonCameraDiscovery()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Search Button
                Button(action: {
                    if discovery.isSearching {
                        discovery.stopDiscovery()
                    } else {
                        discovery.startDiscovery()
                    }
                }) {
                    HStack {
                        if discovery.isSearching {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(discovery.isSearching ? "Stop Search" : "Search for Cameras")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(discovery.isSearching ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                
                // Error Message
                if let errorMessage = discovery.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                }
                
                // Camera List
                if discovery.discoveredCameras.isEmpty && !discovery.isSearching {
                    VStack(spacing: 16) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("No cameras found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Make sure your Canon camera's WiFi is enabled and you're on the same network.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List(discovery.discoveredCameras) { camera in
                        CameraRowView(camera: camera)
                    }
                }
                
                Spacer()
            }
            .navigationTitle("Canon Cameras")
            .onAppear {
                // Auto-search on appear
                discovery.startDiscovery()
            }
        }
    }
}

struct CameraRowView: View {
    let camera: CanonCamera
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(camera.displayName)
                        .font(.headline)
                    
                    Text(camera.modelName)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Connect") {
                    // TODO: Implement connection logic
                    print("Connecting to camera: \(camera.ccapiURL)")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("IP Address:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(camera.ipAddress)
                        .font(.caption)
//                        .fontFamily(.monospaced)
                }
                
                HStack {
                    Text("CCAPI URL:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(camera.ccapiURL)
                        .font(.caption)
//                        .fontFamily(.monospaced)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                
                HStack {
                    Text("Serial:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(camera.serialNumber)
                        .font(.caption)
//                        .fontFamily(.monospaced)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct CameraDiscoveryView_Previews: PreviewProvider {
    static var previews: some View {
        CameraDiscoveryView()
    }
}

