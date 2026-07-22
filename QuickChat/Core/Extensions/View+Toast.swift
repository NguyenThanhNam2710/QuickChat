//
//  View+Toast.swift
//  QuickChat
//
//  Created by NamNT97 on 22/7/26.
//

import SwiftUI
 
private struct ToastOverlayModifier: ViewModifier {
    @Environment(ToastCenter.self) private var toastCenter
 
    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let toast = toastCenter.currentToast {
                    ToastBannerView(toast: toast)
                        .padding(.top, Spacing.xs)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture { toastCenter.dismiss() }
                        .zIndex(1)
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.85), value: toastCenter.currentToast)
    }
}
 
extension View {
    func toastOverlay() -> some View {
        modifier(ToastOverlayModifier())
    }
}
