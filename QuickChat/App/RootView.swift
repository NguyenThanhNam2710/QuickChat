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
                ProgressView("Loading ...")
            }
            .padding()
        case .signedOut:
            LoginView()
        case .signedIn:
            SignedInPlaceholderView()
        }
    }
    
    @ViewBuilder
    private func destinationView(for route: AppRoute) -> some View {
        switch route {
        case .converstationList:
            PlaceholderView(title: "Converstation list", subTitle: "phase 3")
        case .chat(let converstationID):
            PlaceholderView(title: "Chat", subTitle: "ConverstationID: \(converstationID) - phase 4")
        case .profile(let userID):
            PlaceholderView(title: "Profile", subTitle: "userID: \(userID) - phase 5-6")
        }
    }
}

/// View tạm thời để test trọn vòng đăng nhập/đăng xuất trong lúc chờ Giai đoạn 3 (ConversationList).
private struct SignedInPlaceholderView: View {
    @Environment(\.authService) private var authService
    @Environment(AlertCenter.self) private var alertCenter
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Text("Logged in")
                .font(AppFont.title)
            Text("ConversationListView will build in phase 3")
                .font(AppFont.caption)
                .foregroundStyle(.secondary)
            
            Button("Đăng xuất", role: .destructive) {
                alertCenter.showConfirmation(
                    title: "Đăng xuất",
                    message: "Bạn có chắc muốn đăng xuất khỏi QuickChat?",
                    confirmTitle: "Đăng xuất",
                    cancelTitle: "Hủy") {
                        try? authService.signOut()
                    }
            }
            .buttonStyle(.bordered)
            .padding(.top, Spacing.md)
        }
        .padding()
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
