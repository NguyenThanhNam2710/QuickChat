//
//  Message.swift
//  QuickChat
//
//  Created by NamNT97 on 27/7/26.
//

import Foundation

/// Bản chụp tĩnh của tin nhắn được trả lời — CỐ Ý không tự cập nhật nếu tin gốc
/// bị sửa/thu hồi sau đó (trade-off đã chốt ở GiaiDoan5-KeHoach.md, mục STT1).
struct ReplyPreview: Codable, Equatable {
    let senderID: String
    let text: String
}

/// 6 emoji cố định cho reaction — KHÔNG cho chọn tự do.
enum MessageReaction: String, CaseIterable {
    case thumbsUp = "👍"
    case heart = "❤️"
    case laugh = "😂"
    case wow = "😮"
    case sad = "😢"
    case pray = "🙏"
}

/// Context truyền xuống Service khi gửi tin nhắn có trả lời — gộp messageID gốc + preview tĩnh.
struct MessageReplyContext {
    let messageID: String
    let preview: ReplyPreview
}

struct Message: Identifiable, Codable, Equatable {
    let id: String
    let senderID: String
    var text: String
    var timestamp: Date
    var imageURL: String?
    var replyToMessageID: String?
    var replyTo: ReplyPreview?
    /// userID : emoji — mỗi người tối đa 1 reaction/tin nhắn.
    var reactions: [String: String] = [:]
    var isEdited: Bool = false
    /// Thu hồi ghi đè text="" + imageURL=nil trên SERVER, không chỉ ẩn UI —
    /// cờ này để phân biệt "thu hồi" với "tin nhắn rỗng thật".
    var isRecalled: Bool = false
    /// [MỚI GĐ5/STT2] userID : thời điểm user đó "nhìn thấy" tin nhắn này trên màn hình.
    /// THAY THẾ HOÀN TOÀN enum nhị phân `sent/read` cũ. Thiết kế dạng map ngay từ đầu để
    /// tương thích sẵn cho nhóm chat (5B) — không cần đổi schema lần 2.
    var readBy: [String: Date] = [:]
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

extension Message {
    /// Chỉ được sửa nội dung trong vòng 30 phút kể từ lúc gửi.
    var isEditWindowOpen: Bool {
        Date().timeIntervalSince(timestamp) <= 30 * 60
    }
    /// Chỉ được thu hồi trong vòng 15 phút kể từ lúc gửi.
    var isRecallWindowOpen: Bool {
        Date().timeIntervalSince(timestamp) <= 15 * 60
    }
    /// [MỚI GĐ5/STT2] True nếu `userID` đã xem tin nhắn này (khác chính người gửi).
    func isRead(by userID: String) -> Bool {
        readBy[userID] != nil
    }
}
