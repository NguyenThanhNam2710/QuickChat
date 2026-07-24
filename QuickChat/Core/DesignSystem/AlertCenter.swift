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
        confirmTitle: String = L10n.Common.confirm,
        cancelTitle: String = L10n.Common.cancel,
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
