//
//  AppRouter.swift
//  QuickChat
//
//  Created by NamNT97 on 20/7/26.
//

import SwiftUI
import Observation

enum AppRoute: Hashable {
    case chat(converstationID: String)
    case profile(userID: String)
}

@Observable
final class AppRouter {
    
    var path = NavigationPath()
    
    func push(_ route: AppRoute) {
        path.append(route)
    }
    
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    func popToRoot() {
        path = NavigationPath()
    }
    
}
