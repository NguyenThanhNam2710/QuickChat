//
//  AlertCenter.swift
//  QuickChat
//
//  Created by NamNT97 on 22/7/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class AlertCenter {
    private(set) var currentAlert: AppAlert?
    
    func show(title: String, message: String? = nil) {
        currentAlert = AppAlert(title: title, message: message)
    }
    
    func showConfirmation(
        title: String,
        message: String? = nil,
        confirmTitle: String = "Xác nhận",
        cancelTitle: String = "Hủy",
        isDestructive: Bool = true,
        onConfirm: @escaping () -> Void
    ) {
        currentAlert = AppAlert(
            title: title,
            message: message,
            primaryButtonTitle: confirmTitle,
            primaryAction: onConfirm,
            isDestructive: isDestructive,
            secondaryButtonTitle: cancelTitle
        )
    }
    
    func dismiss() {
        currentAlert = nil
    }
}
