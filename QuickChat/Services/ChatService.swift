//
//  ChatService.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import Foundation
import FirebaseFirestore

final class ChatService: ChatServiceProtocol {
    private let db = Firestore.firestore()
    
    func observeConversations(for userID: String) -> AsyncStream<[Conversation]> {
        AsyncStream { continuation in
            let listener = db.collection(Constants.Firestore.conversationsCollection)
                .whereField("participantIDs", arrayContains: userID)
                .order(by: "lastMessageDate", descending: true)
                .addSnapshotListener { snapshot, error in
                    if let error {
                        AppLogger.chat.error("observeConversations lỗi: \(error.localizedDescription, privacy: .public)")
                        return
                    }
                    guard let snapshot else {
                        continuation.yield([])
                        return
                    }
                    let conversations = snapshot.documents.compactMap {
                        Self.mapConversation(id: $0.documentID, data: $0.data())
                    }
                    continuation.yield(conversations)
                }
            
            continuation.onTermination = { _ in
                listener.remove()
            }
        }
    }
    
    // MARK: - Mapping
    // Không dùng FirebaseFirestoreSwift's Codable support (chưa thêm package đó),
    // nên map thủ công từ [String: Any] — rõ ràng, dễ debug, không "magic".
    private static func mapConversation(id: String, data: [String: Any]) -> Conversation? {
        guard let participantIDs = data["participantIDs"] as? [String] else {
            AppLogger.chat.error("Bỏ qua document \(id, privacy: .public) — thiếu participantIDs")
            return nil
        }
        let timestamp = data["lastMessageDate"] as? Timestamp
        return Conversation(
            id: id,
            participantIDs: participantIDs,
            lastMessage: data["lastMessage"] as? String,
            lastMessageDate: timestamp?.dateValue(),
            unreadCounts: data["unreadCounts"] as? [String: Int] ?? [:]
        )
    }
    
    func createOrGetConversation(currentUserID: String, otherUserID: String) async throws -> Conversation {
        let participantIDs = [currentUserID, otherUserID]
        let conversationID = Self.conversationID(for: participantIDs)
        let docRef = db.collection(Constants.Firestore.conversationsCollection).document(conversationID)
        
        return try await AppLogger.chat.logCall(
            "createOrGetConversation",
            header: ["sdk": "Firestore"],
            body: ["participantIDs": participantIDs],
            response: { conversation in ["conversationID": conversation.id] }
        ) {
            let snapshot = try await docRef.getDocument()
            
            // Đã tồn tại (dù ai là người tạo trước) — dùng lại, không ghi đè.
            if snapshot.exists, let data = snapshot.data(),
               let existing = Self.mapConversation(id: snapshot.documentID, data: data) {
                return existing
            }
            
            // Chưa có — tạo mới với unreadCounts = 0 cho cả 2 phía.
            let data: [String: Any] = [
                "participantIDs": participantIDs,
                "lastMessage": NSNull(),
                "lastMessageDate": FieldValue.serverTimestamp(),
                "unreadCounts": [currentUserID: 0, otherUserID: 0]
            ]
            try await docRef.setData(data)
            
            return Conversation(
                id: conversationID,
                participantIDs: participantIDs,
                lastMessage: nil,
                lastMessageDate: Date(),
                unreadCounts: [currentUserID: 0, otherUserID: 0]
            )
        }
    }
    
    /// UID sắp xếp alphabet rồi nối bằng "_" — đảm bảo A tìm B hay B tìm A đều ra cùng 1 ID,
    /// tránh tạo 2 document conversation khác nhau cho cùng 1 cặp người.
    private static func conversationID(for participantIDs: [String]) -> String {
        participantIDs.sorted().joined(separator: "_")
    }
    
    private func messagesCollection(conversationID: String) -> CollectionReference {
        db.collection(Constants.Firestore.conversationsCollection)
            .document(conversationID)
            .collection(Constants.Firestore.messagesSubcollectionName)
    }
    
    func observeLatestMessages(conversationID: String, limit: Int) -> AsyncStream<[MessageSnapshot]> {
        AsyncStream { continuation in
            let listener = messagesCollection(conversationID: conversationID)
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .addSnapshotListener(includeMetadataChanges: true) { snapshot, error in
                    if let error {
                        AppLogger.chat.error("observeLatestMessages lỗi: \(error.localizedDescription, privacy: .public)")
                        // KHÔNG yield rỗng — giữ nguyên tin nhắn đang hiển thị, tránh xóa UI vì lỗi tạm thời.
                        return
                    }
                    guard let snapshot else { return }
                    let items = snapshot.documents.compactMap { doc -> MessageSnapshot? in
                        guard let message = Self.mapMessage(id: doc.documentID, data: doc.data()) else { return nil }
                        return MessageSnapshot(message: message, isPending: doc.metadata.hasPendingWrites)
                    }
                    // Query order descending (mới→cũ) để limit lấy đúng N tin GẦN NHẤT — đảo lại cho UI (cũ→mới).
                    continuation.yield(items.reversed())
                }
            continuation.onTermination = { _ in listener.remove() }
        }
    }
    
    func loadOlderMessages(conversationID: String, before: Date, limit: Int) async throws -> [Message] {
        let snapshot = try await messagesCollection(conversationID: conversationID)
            .order(by: "timestamp", descending: true)
            .whereField("timestamp", isLessThan: Timestamp(date: before))
            .limit(to: limit)
            .getDocuments()
        let messages = snapshot.documents.compactMap { Self.mapMessage(id: $0.documentID, data: $0.data()) }
        return messages.reversed()
    }
    
    func sendMessage(conversationID: String, clientMessageID: String, senderID: String, text: String, otherUserID: String, replyTo: MessageReplyContext?) async throws {
        try await AppLogger.chat.logCall(
            "sendMessage",
            header: ["sdk": "Firestore"],
            body: ["conversationID": conversationID, "senderID": senderID, "hasReply": replyTo != nil]
        ) {
            let messageRef = messagesCollection(conversationID: conversationID).document(clientMessageID)
            let conversationRef = db.collection(Constants.Firestore.conversationsCollection).document(conversationID)
            
            let messageData: [String: Any] = [
                "senderID": senderID,
                "text": text,
                "timestamp": FieldValue.serverTimestamp(),
                "imageURL": NSNull(),
                "reactions": [String: String](),
                "isEdited": false,
                "isRecalled": false,
                // [ĐỔI GĐ5/STT2] Không còn field "status" nhị phân — trạng thái đã đọc
                // giờ suy ra hoàn toàn từ map "readBy", khởi tạo rỗng lúc gửi.
                "readBy": [String: Timestamp](),
                "replyToMessageID": replyTo?.messageID as Any? ?? NSNull(),
                "replyToSenderID": replyTo?.preview.senderID as Any? ?? NSNull(),
                "replyToText": replyTo?.preview.text as Any? ?? NSNull()
            ]
            
            let batch = db.batch()
            batch.setData(messageData, forDocument: messageRef)
            batch.updateData([
                "lastMessage": text,
                "lastMessageDate": FieldValue.serverTimestamp(),
                "unreadCounts.\(otherUserID)": FieldValue.increment(Int64(1))
            ], forDocument: conversationRef)
            
            try await batch.commit()
        }
    }
    
    func editMessage(conversationID: String, messageID: String, newText: String) async throws {
        try await AppLogger.chat.logCall(
            "editMessage", header: ["sdk": "Firestore"],
            body: ["conversationID": conversationID, "messageID": messageID]
        ) {
            try await messagesCollection(conversationID: conversationID)
                .document(messageID)
                .updateData(["text": newText, "isEdited": true])
        }
    }
    
    func recallMessage(conversationID: String, messageID: String) async throws {
        try await AppLogger.chat.logCall(
            "recallMessage", header: ["sdk": "Firestore"],
            body: ["conversationID": conversationID, "messageID": messageID]
        ) {
            try await messagesCollection(conversationID: conversationID)
                .document(messageID)
                .updateData(["text": "", "imageURL": NSNull(), "isRecalled": true])
        }
    }
    
    func setReaction(conversationID: String, messageID: String, userID: String, emoji: String?) async throws {
        let ref = messagesCollection(conversationID: conversationID).document(messageID)
        if let emoji {
            try await ref.updateData(["reactions.\(userID)": emoji])
        } else {
            try await ref.updateData(["reactions.\(userID)": FieldValue.delete()])
        }
    }
    
    func markMessagesAsRead(conversationID: String, messageIDs: [String], currentUserID: String) async throws {
        guard !messageIDs.isEmpty else { return }
        let conversationRef = db.collection(Constants.Firestore.conversationsCollection).document(conversationID)
        let messagesRef = messagesCollection(conversationID: conversationID)
        
        let batch = db.batch()
        for messageID in messageIDs {
            batch.updateData(
                ["readBy.\(currentUserID)": FieldValue.serverTimestamp()],
                forDocument: messagesRef.document(messageID)
            )
        }
        // Reset unreadCounts cùng batch — currentUserID đang thật sự nhìn thấy các tin này.
        batch.updateData(["unreadCounts.\(currentUserID)": 0], forDocument: conversationRef)
        try await batch.commit()
    }
    
    // MARK: - Mapping message
    private static func mapMessage(id: String, data: [String: Any]) -> Message? {
        guard
            let senderID = data["senderID"] as? String,
            let text = data["text"] as? String
        else {
            AppLogger.chat.error("Bỏ qua message \(id, privacy: .public) — thiếu field bắt buộc")
            return nil
        }
        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        
        var replyTo: ReplyPreview?
        if let replySender = data["replyToSenderID"] as? String,
           let replyText = data["replyToText"] as? String {
            replyTo = ReplyPreview(senderID: replySender, text: replyText)
        }
        
        // [MỚI GĐ5/STT2] readBy: [userID: Timestamp] trên Firestore → [userID: Date] ở client.
        let readByRaw = data["readBy"] as? [String: Timestamp] ?? [:]
        let readBy = readByRaw.mapValues { $0.dateValue() }
        
        return Message(
            id: id,
            senderID: senderID,
            text: text,
            timestamp: timestamp,
            imageURL: data["imageURL"] as? String,
            replyToMessageID: data["replyToMessageID"] as? String,
            replyTo: replyTo,
            reactions: data["reactions"] as? [String: String] ?? [:],
            isEdited: data["isEdited"] as? Bool ?? false,
            isRecalled: data["isRecalled"] as? Bool ?? false,
            readBy: readBy
        )
    }
}
