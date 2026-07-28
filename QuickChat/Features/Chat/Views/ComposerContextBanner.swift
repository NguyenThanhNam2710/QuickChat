//
//  ComposerContextBanner.swift
//  QuickChat
//
//  Created by NamNT97 on 28/7/26.
//  Banner nhỏ trên MessageInputBarView khi đang ở chế độ Trả lời/Chỉnh sửa.
//

import SwiftUI

struct ComposerContextBanner: View {
    let title: String
    let preview: String
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 3)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(preview)
                    .font(AppFont.caption)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(.bar)
    }
}
