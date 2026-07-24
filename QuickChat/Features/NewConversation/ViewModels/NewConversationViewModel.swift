//
//  NewConversationViewModel.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class NewConversationViewModel {
    var emailInput: String = ""
    private(set) var isSearching = false
    private(set) var isCreating = false
    private(set) var foundUser: User?
    var errorMessage: String?

    private let userService: UserServiceProtocol
    private let chatService: ChatServiceProtocol
    private let currentUserID: String

    init(userService: UserServiceProtocol, chatService: ChatServiceProtocol, currentUserID: String) {
        self.userService = userService
        self.chatService = chatService
        self.currentUserID = currentUserID
    }

    var isSearchButtonDisabled: Bool {
        !Validators.isValidEmail(emailInput) || isSearching
    }

    func search() async {
        errorMessage = nil
        foundUser = nil
        isSearching = true
        defer { isSearching = false }
        do {
            guard let user = try await userService.fetchUser(byEmail: emailInput) else {
                errorMessage = L10n.NewConversation.userNotFound
                return
            }
            guard user.id != currentUserID else {
                errorMessage = L10n.NewConversation.cannotChatWithSelf
                return
            }
            foundUser = user
        } catch {
            errorMessage = L10n.NewConversation.searchError(error.localizedDescription)
        }
    }

    /// Trả về conversationID nếu tạo/lấy thành công, để View điều hướng sang ChatView.
    @discardableResult
    func startConversation() async -> String? {
        guard let foundUser else { return nil }
        isCreating = true
        defer { isCreating = false }
        do {
            let conversation = try await chatService.createOrGetConversation(
                currentUserID: currentUserID,
                otherUserID: foundUser.id
            )
            return conversation.id
        } catch {
            errorMessage = L10n.NewConversation.createError(error.localizedDescription)
            return nil
        }
    }
}
