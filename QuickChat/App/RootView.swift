//
//  RootView.swift
//  QuickChat
//
//  Created by NamNT97 on 20/7/26.
//

import SwiftUI

struct RootView: View {
    
    @Environment(AppState.self) private var appState
    @Environment(AppRouter.self) private var router
    
    var body: some View {
        @Bindable var router = router
        
        NavigationStack(path: $router.path) {
            content
                .navigationDestination(for: AppRoute.self) { route in
                    destinationView(for: route)
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch appState.authPhase {
        case .loading:
            VStack(spacing: Spacing.md) {
                ProgressView(L10n.Common.loading)
            }
            .padding()
        case .signedOut:
            LoginView()
        case .signedIn:
            ConversationListView()
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .chat(let converstationID):
            PlaceholderView(title: "Chat", subTitle: "ConverstationID: \(converstationID) - phase 4")
        case .profile(_):
            ProfileView()
        }
    }
}

private struct PlaceholderView: View {
    let title: String
    let subTitle: String
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Text(title)
                .font(AppFont.title)
            Text(subTitle)
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
