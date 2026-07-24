//
//  ConversationRowView.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import SwiftUI

struct ConversationRowView: View {
    let item: ConversationDisplayItem
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            avatar
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack {
                    Text(item.displayName)
                        .font(AppFont.body.weight(item.unreadCount > 0 ? .semibold : .regular))
                        .lineLimit(1)
                    Spacer()
                    Text(item.timeText)
                        .font(AppFont.timestamp)
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text(item.lastMessagePreview)
                        .font(AppFont.caption)
                        .foregroundStyle(item.unreadCount > 0 ? .primary : .secondary)
                        .lineLimit(1)
                    Spacer()
                    if item.unreadCount > 0 {
                        unreadBadge
                    }
                }
            }
        }
        .padding(.vertical, Spacing.xs)
        .contentShape(Rectangle())
    }
    
    private var avatar: some View {
        Group {
            if let urlString = item.avatarURL, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        initialsView
                    }
                }
            } else {
                initialsView
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
    }
    
    private var initialsView: some View {
        Circle()
            .fill(AppColor.incomingBubble)
            .overlay(
                Text(item.displayName.prefix(1).uppercased())
                    .font(AppFont.body.weight(.semibold))
                    .foregroundStyle(.secondary)
            )
    }
    
    private var unreadBadge: some View {
        Text("\(item.unreadCount)")
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Circle().fill(Color.accentColor))
    }
}
