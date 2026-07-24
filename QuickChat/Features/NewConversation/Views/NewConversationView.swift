//
//  NewConversationView.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import SwiftUI

struct NewConversationView: View {
    @Environment(\.userService) private var userService
    @Environment(\.chatService) private var chatService
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: NewConversationViewModel?

    /// Gọi khi tạo/lấy conversation thành công — parent (ConversationListView) chịu trách nhiệm
    /// đóng sheet này và push route sang ChatView, giữ NewConversationView không biết gì về AppRouter.
    let onConversationCreated: (String) -> Void

    var body: some View {
        NavigationStack {
            Group {
                if let viewModel {
                    content(viewModel: viewModel)
                } else {
                    Color.clear
                }
            }
            .onAppear {
                if viewModel == nil, let userID = appState.currentUserID {
                    viewModel = NewConversationViewModel(
                        userService: userService,
                        chatService: chatService,
                        currentUserID: userID
                    )
                }
            }
            .navigationTitle(L10n.NewConversation.title)
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Common.cancel) { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func content(viewModel: NewConversationViewModel) -> some View {
        @Bindable var viewModel = viewModel

        Form {
            Section(L10n.NewConversation.searchSectionHeader) {
                HStack {
                    TextField(L10n.NewConversation.emailPlaceholder, text: $viewModel.emailInput)
#if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
#endif
                    Button(L10n.NewConversation.searchButton) {
                        Task { await viewModel.search() }
                    }
                    .disabled(viewModel.isSearchButtonDisabled)
                }

                if viewModel.isSearching {
                    ProgressView()
                }

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(AppFont.caption)
                        .foregroundStyle(.red)
                }
            }

            if let foundUser = viewModel.foundUser {
                Section(L10n.NewConversation.resultSectionHeader) {
                    HStack {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(foundUser.displayName ?? L10n.NewConversation.unknownName)
                                .font(AppFont.body.weight(.semibold))
                            Text(foundUser.email ?? "")
                                .font(AppFont.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if viewModel.isCreating {
                            ProgressView()
                        } else {
                            Button(L10n.NewConversation.startChatButton) {
                                Task {
                                    if let conversationID = await viewModel.startConversation() {
                                        onConversationCreated(conversationID)
                                        dismiss()
                                    }
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
            }
        }
    }
}
