//
//  EnvironmentValues+ChatService.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import SwiftUI

private struct ChatServiceKey: EnvironmentKey {
    static let defaultValue: ChatServiceProtocol = ChatService()
}

extension EnvironmentValues {
    var chatService: ChatServiceProtocol {
        get { self[ChatServiceKey.self] }
        set { self[ChatServiceKey.self] = newValue }
    }
}
