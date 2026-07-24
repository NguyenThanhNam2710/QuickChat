//
//  EnvironmentValues+UserService.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import SwiftUI

private struct UserServiceKey: EnvironmentKey {
    static let defaultValue: UserServiceProtocol = UserService()
}

extension EnvironmentValues {
    var userService: UserServiceProtocol {
        get { self[UserServiceKey.self] }
        set { self[UserServiceKey.self] = newValue }
    }
}
