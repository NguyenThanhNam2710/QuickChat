//
//  ConversationListView.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import SwiftUI

struct ConversationListView: View {
    @Environment(\.chatService) private var chatService
    @Environment(\.userService) private var userService
    @Environment(\.authService) private var authService
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    @Environment(AlertCenter.self) private var alertCenter
    
    @State private var viewModel: ConversationListViewModel?
    @State private var showNewConversation = false
    
    var body: some View {
        Group {
            if let viewModel {
                content(viewModel: viewModel)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            guard viewModel == nil, let userID = appState.currentUserID else { return }
            let vm = ConversationListViewModel(
                chatService: chatService,
                userService: userService,
                currentUserID: userID
            )
            viewModel = vm
            vm.startObserving()
        }
        .navigationTitle(L10n.ConversationList.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showNewConversation = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
            }
            ToolbarItem(placement: .navigation) {
                Button {
                    if let userID = appState.currentUserID {
                        router.push(.profile(userID: userID))
                    }
                } label: {
                    Image(systemName: "person.crop.circle")
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button {
                    signOutTapped()
                } label: {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                }
            }
        }
        .sheet(isPresented: $showNewConversation) {
            NewConversationView { conversationID in
                router.push(.chat(converstationID: conversationID))
            }
        }
    }
    
    @ViewBuilder
    private func content(viewModel: ConversationListViewModel) -> some View {
        if viewModel.isLoading {
            ProgressView(L10n.Common.loading)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if viewModel.items.isEmpty {
            ContentUnavailableView(
                L10n.ConversationList.emptyTitle,
                systemImage: "bubble.left.and.bubble.right",
                description: Text(L10n.ConversationList.emptyDescription)
            )
        } else {
            List(viewModel.items) { item in
                Button {
                    router.push(.chat(converstationID: item.conversation.id))
                } label: {
                    ConversationRowView(item: item)
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)
        }
    }
    
    private func signOutTapped() {
        alertCenter.showConfirmation(
            title: L10n.Root.signOutTitle,
            message: L10n.Root.signOutMessage
        ) {
            try? authService.signOut()
        }
    }
}
