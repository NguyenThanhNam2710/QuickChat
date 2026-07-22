//
//  ToastBannerView.swift
//  QuickChat
//
//  Created by NamNT97 on 22/7/26.
//

import SwiftUI
 
struct ToastBannerView: View {
    let toast: Toast
 
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: toast.type.iconName)
                .foregroundStyle(toast.type.tintColor)
 
            Text(toast.message)
                .font(AppFont.body)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
 
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(toast.type.tintColor.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        .padding(.horizontal, Spacing.md)
    }
}
