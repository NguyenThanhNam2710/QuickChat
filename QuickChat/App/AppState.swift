//
//  AppState.swift
//  QuickChat
//
//  Created by NamNT97 on 20/7/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class AppState {
    
    enum AuthPhase {
        case loading
        case signedOut
        case signedIn(userID: String)
    }
    
    var authPhase: AuthPhase = .loading
    
    var isSignIn: Bool {
        if case .signedIn = authPhase {
            return true
        }
        return false
    }
    
    var currentUserID: String? {
        if case .signedIn(let userID) = authPhase {
            return userID
        }
        return nil
    }
    
    /// Gọi 1 lần từ `.task` ở tầng App (QuickChatApp). Hàm này sẽ chạy suốt vòng đời app,
    /// tự cập nhật authPhase mỗi khi Firebase Auth state đổi (login/logout/token refresh).
    func observeAuthState(_ authService: AuthServiceProtocol, userService: UserServiceProtocol) async {
        if !Self.shouldKeepSignedIn() {
            try? authService.signOut()
        }
        
        for await user in authService.authStateStream {
            if let user {
                authPhase = .signedIn(userID: user.id)
                // Chạy nền, không chặn UI — nếu lỗi mạng thì bỏ qua, lần sau đăng nhập sẽ sync lại.
                Task {
                    try? await userService.syncCurrentUserProfile(user)
                }
            } else {
                authPhase = .signedOut
            }
        }
    }
    
    private static func shouldKeepSignedIn() -> Bool {
        UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.keepSignedIn) as? Bool ?? true
    }
    
}
