//
//  ConversationListViewModel.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import Foundation
import Observation

/// Kết hợp Conversation (Firestore) + User (người còn lại) để View render trực tiếp,
/// không phải tự tra cứu user trong View.
struct ConversationDisplayItem: Identifiable, Equatable {
    var id: String { conversation.id }
    let conversation: Conversation
    let otherUser: User?
    let currentUserID: String
    
    var displayName: String { otherUser?.displayName ?? L10n.ConversationList.unknownUser }
    var avatarURL: String? { otherUser?.avatarURL }
    var lastMessagePreview: String { conversation.lastMessage ?? L10n.ConversationList.noMessageYet }
    var unreadCount: Int { conversation.unreadCount(for: currentUserID) }
    var timeText: String { conversation.lastMessageDate?.chatTimeText() ?? "" }
}

@Observable
@MainActor
final class ConversationListViewModel {
    private(set) var items: [ConversationDisplayItem] = []
    private(set) var isLoading = true
    var errorMessage: String?
    
    private let chatService: ChatServiceProtocol
    private let userService: UserServiceProtocol
    private let currentUserID: String
    
    private var observeTask: Task<Void, Never>?
    /// Cache trong bộ nhớ — tránh gọi lại Firestore cho cùng 1 user mỗi lần snapshot đổi.
    private var userCache: [String: User] = [:]
    
    init(chatService: ChatServiceProtocol, userService: UserServiceProtocol, currentUserID: String) {
        self.chatService = chatService
        self.userService = userService
        self.currentUserID = currentUserID
    }
    
    func startObserving() {
        guard observeTask == nil else { return }
        observeTask = Task {[weak self] in
            guard let self else { return }
            for await conversations in self.chatService.observeConversations(for: self.currentUserID) {
                await self.handle(conversations)
            }
        }
    }
    
    func stopObserving() {
        observeTask?.cancel()
        observeTask = nil
    }
    
    func handle(_ converstations: [Conversation]) async {
        isLoading = false
        var result: [ConversationDisplayItem] = []
        result.reserveCapacity(converstations.count)
        
        for converstation in converstations {
            var otherUser: User?
            if let otherID = converstation.otherParticipantID(currentUserID: currentUserID) {
                if let cached = userCache[otherID] {
                    otherUser = cached
                } else {
                    otherUser = try? await userService.fetchUser(id: otherID)
                    if let otherUser {
                        userCache[otherID] = otherUser
                    }
                }
            }
            result.append(
                ConversationDisplayItem(
                    conversation: converstation,
                    otherUser: otherUser,
                    currentUserID: currentUserID
                )
            )
        }
        items = result
    }
}
