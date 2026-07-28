//
//  ChatViewModel.swift
//  QuickChat
//
//  Created by NamNT97 on 27/7/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class ChatViewModel {
    private(set) var items: [ChatMessageItem] = []
    private(set) var isLoadingInitial = true
    private(set) var isLoadingOlder = false
    private(set) var hasMoreOlder = true
    var draftText: String = ""
    var errorMessage: String?
    
    var replyingTo: ChatMessageItem?
    var editingItem: ChatMessageItem?

    let conversationID: String
    let currentUserID: String
    let otherUserID: String

    private let chatService: ChatServiceProtocol
    private var observeTask: Task<Void, Never>?

    /// Message gửi thất bại THẬT (rules/lỗi dữ liệu) — không bao gồm "đang chờ mạng".
    private var failedMessageIDs: Set<String> = []
    /// Bản sao local của message chưa chắc Firestore đã echo lại kịp — phòng race hiếm gặp.
    private var pendingLocalMessages: [String: Message] = [:]

    init(conversationID: String, currentUserID: String, otherUserID: String, chatService: ChatServiceProtocol) {
        self.conversationID = conversationID
        self.currentUserID = currentUserID
        self.otherUserID = otherUserID
        self.chatService = chatService
    }

    func startObserving() {
        guard observeTask == nil else { return }
        observeTask = Task { [weak self] in
            guard let self else { return }
            for await snapshots in self.chatService.observeLatestMessages(
                conversationID: self.conversationID,
                limit: Constants.Pagination.messagesPageSize
            ) {
                self.handle(snapshots)
            }
        }
    }

    func stopObserving() {
        observeTask?.cancel()
        observeTask = nil
    }

    private func handle(_ snapshots: [MessageSnapshot]) {
        isLoadingInitial = false
        var merged = snapshots.map { snap in
            ChatMessageItem(message: snap.message, isPending: snap.isPending, hasFailed: failedMessageIDs.contains(snap.message.id))
        }
        let knownIDs = Set(merged.map(\.id))
        for (id, message) in pendingLocalMessages where !knownIDs.contains(id) {
            merged.append(ChatMessageItem(message: message, isPending: true, hasFailed: failedMessageIDs.contains(id)))
        }
        items = merged.sorted { $0.message.timestamp < $1.message.timestamp }
    }

    func markAsRead() async {
        guard items.contains(where: { $0.message.senderID != currentUserID && $0.message.status == .sent }) else { return }
        do {
            try await chatService.markMessagesAsRead(conversationID: conversationID, currentUserID: currentUserID)
        } catch {
            // Không cần báo người dùng — không ảnh hưởng luồng gửi/nhận, sẽ tự thử lại khi mở màn hình lần sau.
            AppLogger.chat.error("markAsRead lỗi: \(error.localizedDescription, privacy: .public)")
        }
    }

    func loadOlderMessages() async {
        guard !isLoadingOlder, hasMoreOlder, let oldest = items.first?.message.timestamp else { return }
        isLoadingOlder = true
        defer { isLoadingOlder = false }
        do {
            let older = try await chatService.loadOlderMessages(
                conversationID: conversationID,
                before: oldest,
                limit: Constants.Pagination.messagesPageSize
            )
            hasMoreOlder = older.count == Constants.Pagination.messagesPageSize
            let olderItems = older.map { ChatMessageItem(message: $0, isPending: false, hasFailed: false) }
            items.insert(contentsOf: olderItems, at: 0)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - sendMessage/retrySend/send
    
    func sendMessage() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        guard trimmed.count <= Constants.Validation.maxMessageLength else {
            errorMessage = L10n.Chat.messageTooLong
            return
        }
        let replyContext = replyingTo.map {
            MessageReplyContext(messageID: $0.id, preview: ReplyPreview(senderID: $0.message.senderID, text: $0.message.text))
        }
        draftText = ""
        replyingTo = nil
        send(text: trimmed, replyContext: replyContext)
    }

    func retrySend(itemID: String) {
        guard let failedMessage = pendingLocalMessages[itemID] else { return }
        failedMessageIDs.remove(itemID)
        let replyContext = failedMessage.replyToMessageID.flatMap { id in
            failedMessage.replyTo.map { MessageReplyContext(messageID: id, preview: $0) }
        }
        send(text: failedMessage.text, existingID: itemID, replyContext: replyContext)
    }

    private func send(text: String, existingID: String? = nil, replyContext: MessageReplyContext? = nil) {
        let id = existingID ?? UUID().uuidString
        let localMessage = Message(
            id: id,
            senderID: currentUserID,
            text: text,
            timestamp: Date(),
            status: .sent,
            imageURL: nil,
            replyToMessageID: replyContext?.messageID,
            replyTo: replyContext?.preview
        )
        pendingLocalMessages[id] = localMessage

        if let index = items.firstIndex(where: { $0.id == id }) {
            items[index] = ChatMessageItem(message: localMessage, isPending: true, hasFailed: false)
        } else {
            items.append(ChatMessageItem(message: localMessage, isPending: true, hasFailed: false))
        }

        Task {
            do {
                try await chatService.sendMessage(
                    conversationID: conversationID,
                    clientMessageID: id,
                    senderID: currentUserID,
                    text: text,
                    otherUserID: otherUserID,
                    replyTo: replyContext
                )
                pendingLocalMessages.removeValue(forKey: id)
            } catch {
                failedMessageIDs.insert(id)
                if let index = items.firstIndex(where: { $0.id == id }) {
                    items[index].hasFailed = true
                }
                AppLogger.chat.error("sendMessage thất bại (id: \(id, privacy: .public)) — \(error.localizedDescription, privacy: .public)")
            }
        }
    }
    
    // MARK: - Reply

    func startReply(to item: ChatMessageItem) {
        guard !item.message.isRecalled else { return }
        editingItem = nil
        replyingTo = item
    }

    func cancelReply() {
        replyingTo = nil
    }

    // MARK: - Edit

    func startEdit(item: ChatMessageItem) {
        guard item.message.senderID == currentUserID, !item.message.isRecalled else { return }
        replyingTo = nil
        editingItem = item
        draftText = item.message.text
    }

    func cancelEdit() {
        editingItem = nil
        draftText = ""
    }

    func submitEdit() async {
        guard let editingItem else { return }
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        self.editingItem = nil
        draftText = ""
        do {
            try await chatService.editMessage(conversationID: conversationID, messageID: editingItem.id, newText: trimmed)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Recall

    func recallMessage(item: ChatMessageItem) async {
        guard item.message.senderID == currentUserID else { return }
        do {
            try await chatService.recallMessage(conversationID: conversationID, messageID: item.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Reaction

    func toggleReaction(item: ChatMessageItem, emoji: String) {
        let isRemoving = item.message.reactions[currentUserID] == emoji
        Task {
            do {
                try await chatService.setReaction(
                    conversationID: conversationID,
                    messageID: item.id,
                    userID: currentUserID,
                    emoji: isRemoving ? nil : emoji
                )
            } catch {
                AppLogger.chat.error("setReaction lỗi: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
