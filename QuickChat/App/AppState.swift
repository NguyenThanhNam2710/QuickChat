//
//  AppState.swift
//  QuickChat
//
//  Created by NamNT97 on 20/7/26.
//

import Foundation
import Observation

@Observable
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
}
