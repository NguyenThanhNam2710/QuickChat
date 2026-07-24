//
//  QuickChatApp.swift
//  QuickChat
//
//  Created by NamNT97 on 20/7/26.
//

import SwiftUI
import FirebaseCore

#if os(iOS)
import GoogleSignIn
#endif

@main
struct QuickChatApp: App {
    @State private var appState = AppState()
    @State private var router = AppRouter()
    @State private var toastCenter = ToastCenter()
    @State private var alertCenter = AlertCenter()
    
    private let authService: AuthServiceProtocol
    private let chatService: ChatServiceProtocol
    private let userService: UserServiceProtocol
    
    init() {
#if DEBUG
        FirebaseConfiguration.shared.setLoggerLevel(.error)
#endif
        FirebaseApp.configure()
        authService = AuthService()
        chatService = ChatService()
        userService = UserService()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .id(LocalizationManager.shared.currentLanguage)
                .toastOverlay()
                .alertPresenter()
                .environment(appState)
                .environment(router)
                .environment(toastCenter)
                .environment(alertCenter)
                .environment(\.authService, authService)
                .environment(\.chatService, chatService)
                .environment(\.userService, userService)
                .task {
                    await appState.observeAuthState(authService, userService: userService)
                }
#if os(iOS)
                .onOpenURL { url in
                    GIDSignIn.sharedInstance.handle(url)
                }
#endif
        }
#if os(macOS)
        .windowResizability(.contentSize)
#endif
    }
}
