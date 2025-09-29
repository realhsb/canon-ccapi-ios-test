//
//  CameraDiscoverService.swift
//  CCAPI_test
//
//  Created by Subeen on 9/27/25.
//

import SwiftUI
import Network

@MainActor
class CanonCameraDiscovery: ObservableObject {
    @Published var discoveredCameras: [CanonCamera] = []
    @Published var isSearching = false
    @Published var errorMessage: String?
    
    private let ssdpAddress = "239.255.255.250"
    private let ssdpPort: UInt16 = 1900
    private let searchTarget = "urn:schemas-canon-com:service:ICPO-CameraControlAPIService:1"
    private let receiveTimeout: TimeInterval = 5.0
    private let maxRetries = 3
    
    private var udpConnection: NWConnection?
    private var searchTask: Task<Void, Never>?
    
    // MARK: - Public Methods
    
    func startDiscovery() {
        guard !isSearching else { return }
        
        isSearching = true
        errorMessage = nil
        discoveredCameras.removeAll()
        
        checkNetworkConnectivity()
        
        searchTask = Task {
            await performDiscovery()
        }
    }
    
    private func checkNetworkConnectivity() {
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { path in
            print("🌐 Network status: \(path.status)")
            print("🌐 Available interfaces: \(path.availableInterfaces)")
            if path.status == .satisfied {
                print("✅ Network connection available")
                if let interface = path.availableInterfaces.first {
                    print("📡 Using interface: \(interface)")
                }
            } else {
                print("❌ No network connection")
                Task { @MainActor in
                    self.errorMessage = "No network connection available"
                }
            }
        }
        let queue = DispatchQueue(label: "NetworkMonitor")
        monitor.start(queue: queue)
        
        // Stop monitoring after a short time
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            monitor.cancel()
        }
    }
    
    func stopDiscovery() {
        searchTask?.cancel()
        udpConnection?.cancel()
        isSearching = false
    }
    
    // MARK: - Private Methods
    
    private func performDiscovery() async {
        print("🔍 Starting Canon camera discovery...")
        
        for attempt in 1...maxRetries {
            guard !Task.isCancelled else {
                print("⏹️ Discovery cancelled")
                break
            }
            
            print("📡 Discovery attempt \(attempt)/\(maxRetries)")
            print("🚀 About to call sendMSearchRequest()")  // 이 로그 추가
            await sendMSearchRequest()
            print("✅ sendMSearchRequest() completed")        // 이 로그 추가
            
            // Wait between attempts
            if attempt < maxRetries {
                print("⏳ Waiting 1 second before next attempt") // 이 로그 추가
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            }
        }
        
        await MainActor.run {
            isSearching = false
            if discoveredCameras.isEmpty {
                errorMessage = "No Canon cameras found. Make sure camera WiFi is enabled."
            }
        }
    }
    
    private func sendMSearchRequest() async {
        let msearchRequest = createMSearchRequest()
        let host = NWEndpoint.Host(ssdpAddress)
        let port = NWEndpoint.Port(rawValue: ssdpPort)!
        let endpoint = NWEndpoint.hostPort(host: host, port: port)
        
        print("🔧 Creating UDP connection to \(ssdpAddress):\(ssdpPort)")
        
        let parameters = NWParameters.udp
        parameters.allowLocalEndpointReuse = true
        parameters.includePeerToPeer = true // Add P2P support
        
        udpConnection = NWConnection(to: endpoint, using: parameters)
        
        udpConnection?.stateUpdateHandler = { [weak self] state in
            print("🔧 UDP Connection state: \(state)")
            switch state {
            case .ready:
                print("✅ UDP connection ready, sending M-SEARCH")
                Task {
                    await self?.sendData(msearchRequest)
                }
            case .failed(let error):
                print("❌ UDP connection failed: \(error)")
                Task { @MainActor in
                    self?.errorMessage = "Network connection failed: \(error.localizedDescription)"
                }
            case .waiting(let error):
                print("⏳ UDP connection waiting: \(error)")
            case .preparing:
                print("🔧 UDP connection preparing...")
            case .setup:
                print("🔧 UDP connection setup...")
            case .cancelled:
                print("🚫 UDP connection cancelled")
            @unknown default:
                print("❓ UDP connection unknown state: \(state)")
            }
        }
        
        udpConnection?.start(queue: .global())
        
        // Wait a bit for connection to establish
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // Listen for responses
        await listenForResponses()
        
        udpConnection?.cancel()
    }
    
    private func createMSearchRequest() -> Data {
        let msearch = """
        M-SEARCH * HTTP/1.1\r
        HOST: \(ssdpAddress):\(ssdpPort)\r
        MAN: "ssdp:discover"\r
        MX: 1\r
        ST: \(searchTarget)\r
        \r
        
        """
        return msearch.data(using: .utf8)!
    }
    
    private func sendData(_ data: Data) {
        udpConnection?.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("❌ Failed to send M-SEARCH: \(error)")
            } else {
                print("📤 M-SEARCH request sent")
            }
        })
    }
    
    private func listenForResponses() async {
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < receiveTimeout && !Task.isCancelled {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                udpConnection?.receive(minimumIncompleteLength: 1, maximumLength: 2048) { [weak self] data, _, isComplete, error in
                    defer { continuation.resume() }
                    
                    if let error = error {
                        print("❌ Receive error: \(error)")
                        return
                    }
                    
                    guard let data = data,
                          let response = String(data: data, encoding: .utf8) else {
                        return
                    }
                    
                    print("📥 Received SSDP response")
                    Task {
                        await self?.processSSDPResponse(response)
                    }
                }
            }
            
            // Small delay between receive attempts
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    private func processSSDPResponse(_ response: String) async {
        print("🔍 Processing SSDP response...")
        
        // Extract Location header
        guard let locationURL = extractLocationURL(from: response) else {
            print("⚠️ No Location header found in response")
            return
        }
        
        print("📍 Found device description URL: \(locationURL)")
        
        // Download and parse device description
        await downloadDeviceDescription(from: locationURL)
    }
    
    private func extractLocationURL(from response: String) -> String? {
        let lines = response.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.lowercased().hasPrefix("location:") {
                let location = trimmed.dropFirst(9).trimmingCharacters(in: .whitespacesAndNewlines)
                return location
            }
        }
        
        return nil
    }
    
    private func downloadDeviceDescription(from urlString: String) async {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid device description URL: \(urlString)")
            return
        }
        
        do {
            print("⬇️ Downloading device description...")
            let (data, _) = try await URLSession.shared.data(from: url)
            
            guard let xmlString = String(data: data, encoding: .utf8) else {
                print("❌ Failed to decode device description XML")
                return
            }
            
            print("📄 Device description XML downloaded")
            await parseDeviceDescription(xmlString, sourceURL: urlString)
            
        } catch {
            print("❌ Failed to download device description: \(error)")
        }
    }
    
    private func parseDeviceDescription(_ xmlString: String, sourceURL: String) async {
        let parser = DeviceDescriptionParser()
        
        guard let deviceInfo = parser.parse(xmlString) else {
            print("❌ Failed to parse device description XML")
            return
        }
        
        // Extract IP address from source URL for display
        let ipAddress = extractIPAddress(from: sourceURL)
        
        let camera = CanonCamera(
            friendlyName: deviceInfo.friendlyName,
            modelName: deviceInfo.modelName,
            serialNumber: deviceInfo.serialNumber,
            udn: deviceInfo.udn,
            ccapiURL: deviceInfo.ccapiURL,
            ipAddress: ipAddress
        )
        
        await MainActor.run {
            // Check if camera already exists (by UDN)
            if !discoveredCameras.contains(where: { $0.udn == camera.udn }) {
                discoveredCameras.append(camera)
                print("📸 Found Canon camera: \(camera.displayName) at \(camera.ccapiURL)")
            }
        }
    }
    
    private func extractIPAddress(from urlString: String) -> String {
        guard let url = URL(string: urlString),
              let host = url.host else {
            return "Unknown"
        }
        return host
    }
}
