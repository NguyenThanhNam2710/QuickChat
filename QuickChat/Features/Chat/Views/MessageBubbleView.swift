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
    let otherUserID: String
    let onRetry: () -> Void
    let onReply: () -> Void
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onRecall: () -> Void
    let onReact: (String) -> Void
    
    @State private var showReactionPicker = false
    
    var body: some View {
        HStack {
            if isOutgoing { Spacer(minLength: 40) }
            
            VStack(alignment: isOutgoing ? .trailing : .leading, spacing: Spacing.xs) {
                if showReactionPicker {
                    reactionPickerBar
                }
                
                bubbleContent
                
                if !groupedReactions.isEmpty {
                    reactionRow
                }
                statusFooter
            }
            
            if !isOutgoing { Spacer(minLength: 40) }
        }
    }
    
    private var reactionPickerBar: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(MessageReaction.allCases, id: \.rawValue) { reaction in
                Button {
                    onReact(reaction.rawValue)
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        showReactionPicker = false
                    }
                } label: {
                    Text(reaction.rawValue)
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xs)
        .background(.regularMaterial, in: Capsule())
        .transition(.scale(scale: 0.85).combined(with: .opacity))
    }
    
    @ViewBuilder
    private var bubbleContent: some View {
        MessageBubbleContentView(message: item.message, isOutgoing: isOutgoing, currentUserID: currentUserID)
            .contextMenu {
                if !item.message.isRecalled {
                    //                    ControlGroup {
                    //                        ForEach(MessageReaction.allCases, id: \.rawValue) { reaction in
                    //                            Button {
                    //                                onReact(reaction.rawValue)
                    //                            } label: {
                    //                                Text(reaction.rawValue)
                    //                            }
                    //                        }
                    //                    }
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            showReactionPicker = true
                        }
                    } label: {
                        Label(L10n.Chat.react, systemImage: "face.smiling")
                    }
                    
                    Button {
                        onReply()
                    } label: {
                        Label(L10n.Chat.reply, systemImage: "arrowshape.turn.up.left")
                    }
                    Button {
                        onCopy()
                    } label: {
                        Label(L10n.Chat.copyText, systemImage: "doc.on.doc")
                    }
                    if isOutgoing {
                        if item.message.isEditWindowOpen {
                            Button {
                                onEdit()
                            } label: {
                                Label(L10n.Chat.edit, systemImage: "pencil")
                            }
                        }
                        if item.message.isRecallWindowOpen {
                            Button(role: .destructive) {
                                onRecall()
                            } label: {
                                Label(L10n.Chat.recall, systemImage: "arrow.uturn.backward")
                            }
                        }
                    }
                }
            }
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
                // [ĐỔI GĐ5/STT2] Đã đọc giờ tra theo readBy[otherUserID] của CHÍNH tin nhắn này —
                // không còn field "status" nhị phân dùng chung cho cả conversation.
                if isOutgoing, item.message.isRead(by: otherUserID) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(AppFont.timestamp)
                        .foregroundStyle(.blue)
                }
            }
        }
    }
}
