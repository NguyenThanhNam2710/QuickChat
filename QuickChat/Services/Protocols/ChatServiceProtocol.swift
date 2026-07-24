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
    
}
