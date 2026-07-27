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

    func sendMessage(conversationID: String, clientMessageID: String, senderID: String, text: String, otherUserID: String) async throws {
        try await AppLogger.chat.logCall(
            "sendMessage",
            header: ["sdk": "Firestore"],
            body: ["conversationID": conversationID, "senderID": senderID]
        ) {
            let messageRef = messagesCollection(conversationID: conversationID).document(clientMessageID)
            let conversationRef = db.collection(Constants.Firestore.conversationsCollection).document(conversationID)

            let batch = db.batch()
            batch.setData([
                "senderID": senderID,
                "text": text,
                "timestamp": FieldValue.serverTimestamp(),
                "status": MessageStatus.sent.rawValue,
                "imageURL": NSNull()
            ], forDocument: messageRef)

            batch.updateData([
                "lastMessage": text,
                "lastMessageDate": FieldValue.serverTimestamp(),
                "unreadCounts.\(otherUserID)": FieldValue.increment(Int64(1))
            ], forDocument: conversationRef)

            try await batch.commit()
        }
    }

    func markMessagesAsRead(conversationID: String, currentUserID: String) async throws {
        let conversationRef = db.collection(Constants.Firestore.conversationsCollection).document(conversationID)

        let snapshot = try await messagesCollection(conversationID: conversationID)
            .whereField("senderID", isNotEqualTo: currentUserID)
            .whereField("status", isEqualTo: MessageStatus.sent.rawValue)
            .getDocuments()

        let batch = db.batch()
        for doc in snapshot.documents {
            batch.updateData(["status": MessageStatus.read.rawValue], forDocument: doc.reference)
        }
        // Luôn reset unreadCounts về 0 dù không có message nào cần đổi status,
        // tránh lệch đếm nếu có race condition với sendMessage của phía kia.
        batch.updateData(["unreadCounts.\(currentUserID)": 0], forDocument: conversationRef)
        try await batch.commit()
    }

    // MARK: - Mapping message
    private static func mapMessage(id: String, data: [String: Any]) -> Message? {
        guard
            let senderID = data["senderID"] as? String,
            let text = data["text"] as? String,
            let statusRaw = data["status"] as? String,
            let status = MessageStatus(rawValue: statusRaw)
        else {
            AppLogger.chat.error("Bỏ qua message \(id, privacy: .public) — thiếu field bắt buộc")
            return nil
        }
        // Tin vừa gửi (serverTimestamp chưa resolve khi offline) chưa có "timestamp" thật — fallback Date()
        // để không bị loại khỏi danh sách hiển thị trong lúc chờ đồng bộ.
        let timestamp = (data["timestamp"] as? Timestamp)?.dateValue() ?? Date()
        return Message(
            id: id,
            senderID: senderID,
            text: text,
            timestamp: timestamp,
            status: status,
            imageURL: data["imageURL"] as? String
        )
    }
}
