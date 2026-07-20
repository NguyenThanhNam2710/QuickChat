//
//  Colors.swift
//  QuickChat
//
//  Created by NamNT97 on 20/7/26.
//

import SwiftUI

enum AppColor {
    /// Nền chính của màn hình.
    static let background: Color = {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(uiColor: .systemBackground)
        #endif
    }()

    /// Bubble tin nhắn của chính mình.
    static let outgoingBubble = Color.accentColor

    /// Bubble tin nhắn của người khác.
    static let incomingBubble: Color = {
        #if os(macOS)
        return Color(nsColor: .controlBackgroundColor)
        #else
        return Color(uiColor: .secondarySystemBackground)
        #endif
    }()

    static let separator: Color = {
        #if os(macOS)
        return Color(nsColor: .separatorColor)
        #else
        return Color(uiColor: .separator)
        #endif
    }()
}
