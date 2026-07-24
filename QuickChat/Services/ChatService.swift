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
                        continuation.yield([])
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
}
