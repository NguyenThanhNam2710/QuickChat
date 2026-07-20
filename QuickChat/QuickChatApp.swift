//
//  QuickChatApp.swift
//  QuickChat
//
//  Created by NamNT97 on 20/7/26.
//

import SwiftUI
import FirebaseCore


@main
struct QuickChatApp: App {
    @State private var appState = AppState()
    @State private var router = AppRouter()
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(router)
        }
#if os(macOS)
        .windowResizability(.contentSize)
#endif
    }
}
