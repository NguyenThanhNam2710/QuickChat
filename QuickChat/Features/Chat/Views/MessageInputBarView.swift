//
//  MessageInputBarView.swift
//  QuickChat
//
//  Created by NamNT97 on 27/7/26.
//

import SwiftUI

struct MessageInputBarView: View {
    @Binding var text: String
    let onSend: () -> Void

    var body: some View {
        HStack(alignment: .bottom, spacing: Spacing.sm) {
            TextField(L10n.Chat.inputPlaceholder, text: $text, axis: .vertical)
                .lineLimit(1...5)
                .textFieldStyle(.roundedBorder)

            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.bar)
        .safeAreaInset(edge: .bottom) { Color.clear.frame(height: 0) }
    }
}
