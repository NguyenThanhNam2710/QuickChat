//
//  UserService.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import Foundation
import FirebaseFirestore

final class UserService: UserServiceProtocol {
    private let db = Firestore.firestore()
    
    func fetchUser(id: String) async throws -> User? {
        let snapshot = try await db.collection(Constants.Firestore.usersCollection)
            .document(id)
            .getDocument()
        
        guard snapshot.exists, let data = snapshot.data() else { return nil }
        return Self.mapUser(id: snapshot.documentID, data: data)
    }
    
    /// Services/UserService.swift  — syncCurrentUserProfile  LUÔN lưu email chữ thường
    /// (Firestore so khớp string phân biệt hoa/thường, nếu không chuẩn hoá thì search sẽ hay "không tìm thấy")
    func syncCurrentUserProfile(_ user: User) async throws {
        var data: [String: Any] = [
            "lastSeen": FieldValue.serverTimestamp()
        ]
        data["email"] = user.email?.lowercased()
        data["displayName"] = user.displayName
        data["avatarURL"] = user.avatarURL
        
        try await db.collection(Constants.Firestore.usersCollection)
            .document(user.id)
            .setData(data, merge: true)
    }
    
    func fetchUser(byEmail email: String) async throws -> User? {
        let normalizedEmail = email.lowercased().trimmingCharacters(in: .whitespaces)
        
        let snapshot = try await db.collection(Constants.Firestore.usersCollection)
            .whereField("email", isEqualTo: normalizedEmail)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else { return nil }
        return Self.mapUser(id: document.documentID, data: document.data())
    }
    
    private static func mapUser(id: String, data: [String: Any]) -> User {
        User(
            id: id,
            email: data["email"] as? String,
            displayName: data["displayName"] as? String,
            avatarURL: data["avatarURL"] as? String,
            lastSeen: (data["lastSeen"] as? Timestamp)?.dateValue()
        )
    }
}
