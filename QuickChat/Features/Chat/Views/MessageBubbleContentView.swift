//
//  MessageBubbleContentView.swift
//  QuickChat
//
//  Created by NamNT97 on 29/7/26.
//  View THUẦN hiển thị nội dung bubble — không gesture, không context menu.
//  Dùng chung cho MessageBubbleView (danh sách chat) và MessageActionOverlay (bản replica khi long-press).
//

import SwiftUI

struct MessageBubbleContentView: View {
    let message: Message
    let isOutgoing: Bool
    let currentUserID: String

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let replyTo = message.replyTo {
                replyPreview(replyTo)
            }
            if message.isRecalled {
                Text(L10n.Chat.recalledMessage)
                    .font(AppFont.messageBubble.italic())
                    .foregroundStyle(isOutgoing ? .white.opacity(0.75) : .secondary)
            } else {
                Text(message.text)
                    .font(AppFont.messageBubble)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(isOutgoing ? AppColor.outgoingBubble : AppColor.incomingBubble)
        .foregroundStyle(isOutgoing ? .white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func replyPreview(_ preview: ReplyPreview) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(preview.senderID == currentUserID ? L10n.Chat.replyToYou : L10n.Chat.replyToOther)
                .font(AppFont.timestamp.weight(.semibold))
            Text(preview.text)
                .font(AppFont.caption)
                .lineLimit(1)
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background((isOutgoing ? Color.white : Color.primary).opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
