//
//  LiveViewModel.swift
//  CCAPI_test
//
//  Created by Subeen on 10/15/25.
//

import Foundation

import SwiftUI
import Moya

final class LiveViewModel: ObservableObject {
    @Published var currentImage: UIImage?
    private let service = LiveViewStreamService()
    
    init() {
        NotificationCenter.default.addObserver(forName: .didReceiveLiveViewImage, object: nil, queue: .main) { [weak self] notif in
            self?.currentImage = notif.object as? UIImage
        }
    }
    
    func start() async {
        try? await service.startLiveView()
        try? await service.startStream()
    }
    
    func stop() async {
        try? await service.stopLiveView()
    }
}
