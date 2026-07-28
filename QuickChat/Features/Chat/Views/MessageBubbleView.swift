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
    let currentUserID: String
    let onRetry: () -> Void
    let onReply: () -> Void
    let onEdit: () -> Void
    let onRecall: () -> Void
    let onReact: (String) -> Void

    var body: some View {
        HStack {
            if isOutgoing { Spacer(minLength: 40) }

            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: Spacing.xs) {
                bubbleContent
                if !groupedReactions.isEmpty {
                    reactionRow
                }
                statusFooter
            }

            if !isOutgoing { Spacer(minLength: 40) }
        }
    }

    @ViewBuilder
    private var bubbleContent: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            if let replyTo = item.message.replyTo {
                replyPreview(replyTo)
            }
            if item.message.isRecalled {
                Text(L10n.Chat.recalledMessage)
                    .font(AppFont.messageBubble.italic())
                    .foregroundStyle(isOutgoing ? .white.opacity(0.75) : .secondary)
            } else {
                Text(item.message.text)
                    .font(AppFont.messageBubble)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(isOutgoing ? AppColor.outgoingBubble : AppColor.incomingBubble)
        .foregroundStyle(isOutgoing ? .white : .primary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contextMenu {
            if !item.message.isRecalled {
                Button {
                    onReply()
                } label: {
                    Label(L10n.Chat.reply, systemImage: "arrowshape.turn.up.left")
                }
                if isOutgoing {
                    Button {
                        onEdit()
                    } label: {
                        Label(L10n.Chat.edit, systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        onRecall()
                    } label: {
                        Label(L10n.Chat.recall, systemImage: "arrow.uturn.backward")
                    }
                }
                Menu {
                    ForEach(MessageReaction.allCases, id: \.rawValue) { reaction in
                        Button(reaction.rawValue) { onReact(reaction.rawValue) }
                    }
                } label: {
                    Label(L10n.Chat.react, systemImage: "face.smiling")
                }
            }
        }
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

    private var groupedReactions: [(emoji: String, count: Int)] {
        let counts = Dictionary(grouping: item.message.reactions.values, by: { $0 }).mapValues(\.count)
        return counts.map { (emoji: $0.key, count: $0.value) }.sorted { $0.emoji < $1.emoji }
    }

    private var reactionRow: some View {
        HStack(spacing: Spacing.xs) {
            ForEach(groupedReactions, id: \.emoji) { reaction in
                Button {
                    onReact(reaction.emoji)
                } label: {
                    HStack(spacing: 2) {
                        Text(reaction.emoji)
                        if reaction.count > 1 {
                            Text("\(reaction.count)").font(.caption2)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.regularMaterial, in: Capsule())
                }
                .buttonStyle(.plain)
            }
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
                HStack(spacing: 2) {
                    Text(item.message.timestamp.chatTimeText())
                    if item.message.isEdited {
                        Text(L10n.Chat.editedSuffix)
                    }
                }
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
