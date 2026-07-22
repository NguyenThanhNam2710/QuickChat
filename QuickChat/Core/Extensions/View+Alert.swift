//
//  View+Alert.swift
//  QuickChat
//
//  Created by NamNT97 on 22/7/26.
//

import SwiftUI
 
private struct AlertPresenterModifier: ViewModifier {
    @Environment(AlertCenter.self) private var alertCenter
 
    func body(content: Content) -> some View {
        content
            .alert(
                alertCenter.currentAlert?.title ?? "",
                isPresented: Binding(
                    get: { alertCenter.currentAlert != nil },
                    set: { isPresented in
                        if !isPresented { alertCenter.dismiss() }
                    }
                ),
                presenting: alertCenter.currentAlert
            ) { alert in
                if let secondaryTitle = alert.secondaryButtonTitle {
                    Button(secondaryTitle, role: .cancel) {}
                }
                Button(alert.primaryButtonTitle, role: alert.isDestructive ? .destructive : nil) {
                    alert.primaryAction?()
                }
            } message: { alert in
                if let message = alert.message {
                    Text(message)
                }
            }
    }
}
 
extension View {
    func alertPresenter() -> some View {
        modifier(AlertPresenterModifier())
    }
}
