//
//  EnvironmentValues+AuthService.swift
//  QuickChat
//
//  Created by NamNT97 on 21/7/26.
//  Giai đoạn 2 — cho phép inject AuthServiceProtocol qua Environment,
//  đúng tinh thần "Dependency Injection qua init/Environment" trong Roadmap mục 6.
//  Nhờ đây, unit test hoặc SwiftUI Preview có thể thay bằng MockAuthService dễ dàng.
//

import SwiftUI

private struct AuthServiceKey: EnvironmentKey {
    static let defaultValue: AuthServiceProtocol = AuthService()
}

extension EnvironmentValues {
    var authService: AuthServiceProtocol {
        get { self[AuthServiceKey.self] }
        set { self[AuthServiceKey.self] = newValue }
    }
}
