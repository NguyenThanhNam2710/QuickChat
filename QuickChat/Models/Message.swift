//
//  Message.swift
//  QuickChat
//
//  Created by NamNT97 on 27/7/26.
//

import Foundation

enum MessageStatus: String, Codable {
    case sent
    case read
}

struct Message: Identifiable, Codable, Equatable {
    let id: String
    let senderID: String
    var text: String
    var timestamp: Date
    var status: MessageStatus
    var imageURL: String?
}

/// Bọc Message + trạng thái đồng bộ phía client — dùng để render UI (icon đồng hồ/nút Retry).
struct MessageSnapshot: Equatable {
    let message: Message
    let isPending: Bool
}

struct ChatMessageItem: Identifiable, Equatable {
    var message: Message
    var isPending: Bool
    var hasFailed: Bool
    var id: String { message.id }
}
