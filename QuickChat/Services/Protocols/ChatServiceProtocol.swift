//
//  ChatServiceProtocol.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import Foundation

protocol ChatServiceProtocol {
    /// Stream danh sách cuộc trò chuyện của 1 user — bọc từ Firestore `addSnapshotListener`
    /// (callback) sang AsyncStream, cùng nguyên tắc đã dùng ở AuthService.authStateStream.
    func observeConversations(for userID: String) -> AsyncStream<[Conversation]>
    
    /// Tạo conversation mới nếu chưa tồn tại giữa 2 user, hoặc trả về conversation đã có sẵn.
    /// ID được sinh xác định từ cặp UID (sắp xếp + nối) nên gọi nhiều lần vẫn ra cùng 1 document,
    /// không tạo trùng conversation cho cùng 1 cặp người.
    func createOrGetConversation(currentUserID: String, otherUserID: String) async throws -> Conversation
    
    /// Lắng nghe realtime trang tin nhắn MỚI NHẤT (limit), kèm metadata cho biết
    /// message đang chờ đồng bộ (offline/chưa server ACK) hay đã đồng bộ xong.
    func observeLatestMessages(conversationID: String, limit: Int) -> AsyncStream<[MessageSnapshot]>
    
    /// Tải thêm tin nhắn CŨ HƠN mốc `before` — one-shot (không realtime), dùng cho infinite scroll.
    func loadOlderMessages(conversationID: String, before: Date, limit: Int) async throws -> [Message]
    
    /// Gửi tin nhắn — ghi message + cập nhật lastMessage/lastMessageDate/unreadCounts trong CÙNG 1 batch.
    /// `clientMessageID` do ViewModel sinh trước (UUID) để Optimistic UI và dữ liệu thật dùng chung 1 ID.
    /// `replyTo` = nil nếu gửi tin nhắn thường, có giá trị nếu đang trả lời 1 tin khác.
    func sendMessage(conversationID: String, clientMessageID: String, senderID: String, text: String, otherUserID: String, replyTo: MessageReplyContext?) async throws

    /// Sửa nội dung tin nhắn — chỉ chủ tin nhắn được sửa, KHÔNG giới hạn thời gian (đã chốt).
    func editMessage(conversationID: String, messageID: String, newText: String) async throws

    /// Thu hồi tin nhắn — ghi đè text/imageURL trên server, đặt isRecalled = true.
    func recallMessage(conversationID: String, messageID: String) async throws

    /// Đặt/gỡ reaction của 1 user cho 1 tin nhắn. Truyền emoji = nil để gỡ.
    func setReaction(conversationID: String, messageID: String, userID: String, emoji: String?) async throws
    
    /// Đánh dấu toàn bộ tin nhắn CHƯA đọc (gửi bởi người khác) trong conversation là đã đọc,
    /// đồng thời reset unreadCounts của currentUserID về 0.
    func markMessagesAsRead(conversationID: String, currentUserID: String) async throws
    
}
