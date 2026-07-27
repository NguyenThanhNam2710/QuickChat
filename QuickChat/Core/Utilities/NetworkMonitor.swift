//
//  NetworkMonitor.swift
//  QuickChat
//
//  Created by NamNT97 on 27/7/26.
//

import Foundation
import Network
import Observation

@Observable
@MainActor
final class NetworkMonitor {
    private(set) var isConnected = true
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.N.QuickChat.NetworkMonitor")

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                AppLogger.network.info("NWPath status: \(String(describing: path.status), privacy: .public) lúc \(Date(), privacy: .public)")
                self?.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    /// Đọc lại trạng thái path hiện tại theo yêu cầu — dự phòng cho trường hợp
    /// pathUpdateHandler không được OS gọi lại (đã gặp trên Simulator khi ngắt/khôi phục
    /// mạng ở tầng host Mac). Không thay thế callback, chỉ bổ sung "double-check".
    func refreshCurrentPathStatus() {
        let status = monitor.currentPath.status
        AppLogger.network.info("Manual refresh NWPath status: \(String(describing: status), privacy: .public)")
        isConnected = status == .satisfied
    }

    deinit {
        monitor.cancel()
    }
}
