//
//  Conversation.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import Foundation

struct Conversation: Identifiable, Codable, Equatable {
    let id: String
    var participantIDs: [String]
    var lastMessage: String?
    var lastMessageDate: Date?
    var unreadCounts: [String: Int]
    
    func unreadCount(for userID: String) -> Int {
        unreadCounts[userID] ?? 0
    }
    
    func otherParticipantID(currentUserID: String) -> String? {
        participantIDs.first { $0 != currentUserID }
    }
}
