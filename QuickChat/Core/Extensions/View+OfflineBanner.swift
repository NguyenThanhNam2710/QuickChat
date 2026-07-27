//
//  View+OfflineBanner.swift
//  QuickChat
//
//  Created by NamNT97 on 27/7/26.
//

import SwiftUI

private struct OfflineBannerModifier: ViewModifier {
    @Environment(NetworkMonitor.self) private var networkMonitor

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            if !networkMonitor.isConnected {
                HStack(spacing: Spacing.xs) {
                    Image(systemName: "wifi.slash")
                    Text(L10n.Common.offlineBanner)
                }
                .font(AppFont.caption)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xs)
                .background(Color.red)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            content
        }
        .animation(.easeInOut(duration: 0.25), value: networkMonitor.isConnected)
    }
}

extension View {
    func offlineBanner() -> some View {
        modifier(OfflineBannerModifier())
    }
}
