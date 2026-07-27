//
//  MessageBubbleView.swift
//  QuickChat
//
//  Created by NamNT97 on 27/7/26.
//

import SwiftUI

struct MessageBubbleView: View {
    let item: ChatMessageItem
    let isOutgoing: Bool
    let onRetry: () -> Void

    var body: some View {
        HStack {
            if isOutgoing { Spacer(minLength: 40) }

            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: Spacing.xs) {
                Text(item.message.text)
                    .font(AppFont.messageBubble)
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xs)
                    .background(isOutgoing ? AppColor.outgoingBubble : AppColor.incomingBubble)
                    .foregroundStyle(isOutgoing ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                statusFooter
            }

            if !isOutgoing { Spacer(minLength: 40) }
        }
    }

    @ViewBuilder
    private var statusFooter: some View {
        HStack(spacing: Spacing.xs) {
            if item.hasFailed {
                Button(action: onRetry) {
                    Label(L10n.Chat.retrySend, systemImage: "exclamationmark.arrow.circlepath")
                        .font(AppFont.timestamp)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
            } else if item.isPending {
                Image(systemName: "clock")
                    .font(AppFont.timestamp)
                    .foregroundStyle(.secondary)
            } else {
                Text(item.message.timestamp.chatTimeText())
                    .font(AppFont.timestamp)
                    .foregroundStyle(.secondary)
                if isOutgoing, item.message.status == .read {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppFont.timestamp)
                        .foregroundStyle(.blue)
                }
            }
        }
    }
}
