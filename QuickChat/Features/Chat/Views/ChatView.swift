//
//  ChatView.swift
//  QuickChat
//
//  Created by NamNT97 on 27/7/26.
//

import SwiftUI

struct ChatView: View {
    @Environment(\.chatService) private var chatService
    @Environment(AppState.self) private var appState
    @State private var viewModel: ChatViewModel?

    let conversationID: String
    let otherUserID: String

    var body: some View {
        Group {
            if let viewModel {
                content(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .navigationTitle(L10n.Chat.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .task(id: conversationID) {
            guard let userID = appState.currentUserID else { return }
            let vm = ChatViewModel(
                conversationID: conversationID,
                currentUserID: userID,
                otherUserID: otherUserID,
                chatService: chatService
            )
            viewModel = vm
            vm.startObserving()
            await vm.markAsRead()
        }
    }

    @ViewBuilder
    private func content(viewModel: ChatViewModel) -> some View {
        @Bindable var viewModel = viewModel

        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: Spacing.xs) {
                        if viewModel.isLoadingOlder {
                            ProgressView().padding(.vertical, Spacing.sm)
                        }
                        // Trigger vô hình ở đầu danh sách — kéo lên chạm tới đây thì tải thêm tin cũ.
                        Color.clear
                            .frame(height: 1)
                            .onAppear { Task { await viewModel.loadOlderMessages() } }

                        ForEach(viewModel.items) { item in
                            MessageBubbleView(
                                item: item,
                                isOutgoing: item.message.senderID == viewModel.currentUserID,
                                currentUserID: viewModel.currentUserID,
                                onRetry: { viewModel.retrySend(itemID: item.id) },
                                onReply: { viewModel.startReply(to: item) },
                                onEdit: { viewModel.startEdit(item: item) },
                                onRecall: { Task { await viewModel.recallMessage(item: item) } },
                                onReact: { emoji in viewModel.toggleReaction(item: item, emoji: emoji) }
                            )
                            .id(item.id)
                        }
                    }
                    .padding(.horizontal, Spacing.md)
                }
                .onChange(of: viewModel.items.last?.id) { _, newID in
                    guard let newID else { return }
                    withAnimation { proxy.scrollTo(newID, anchor: .bottom) }
                }
                .onAppear {
                    if let lastID = viewModel.items.last?.id {
                        proxy.scrollTo(lastID, anchor: .bottom)
                    }
                }
            }

            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .font(AppFont.caption)
                    .foregroundStyle(.red)
                    .padding(.horizontal, Spacing.md)
            }

            if let replyingTo = viewModel.replyingTo {
                ComposerContextBanner(
                    title: L10n.Chat.replyingToLabel,
                    preview: replyingTo.message.text,
                    onCancel: { viewModel.cancelReply() }
                )
            }
            if viewModel.editingItem != nil {
                ComposerContextBanner(
                    title: L10n.Chat.editingLabel,
                    preview: viewModel.draftText,
                    onCancel: { viewModel.cancelEdit() }
                )
            }

            MessageInputBarView(text: $viewModel.draftText) {
                if viewModel.editingItem != nil {
                    Task { await viewModel.submitEdit() }
                } else {
                    viewModel.sendMessage()
                }
            }
        }
        .background(AppColor.background)
    }
}
