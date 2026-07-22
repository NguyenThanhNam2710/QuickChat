//
//  ToastCenter.swift
//  QuickChat
//
//  Created by NamNT97 on 22/7/26.
//

import Foundation
import Observation
 
@Observable
@MainActor
final class ToastCenter {
    private(set) var currentToast: Toast?
    private var dismissTask: Task<Void, Never>?
 
    func show(_ message: String, type: ToastType = .info, duration: TimeInterval = 2.5) {
        dismissTask?.cancel()
        currentToast = Toast(message: message, type: type)
        dismissTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard !Task.isCancelled else { return }
            self?.currentToast = nil
        }
    }
 
    func dismiss() {
        dismissTask?.cancel()
        currentToast = nil
    }
}
