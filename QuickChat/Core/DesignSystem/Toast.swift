//
//  Toast.swift
//  QuickChat
//
//  Created by NamNT97 on 22/7/26.
//

import SwiftUI
 
enum ToastType {
    case success
    case error
    case info
 
    var iconName: String {
        switch self {
        case .success: return "checkmark.circle.fill"
        case .error: return "xmark.circle.fill"
        case .info: return "info.circle.fill"
        }
    }
 
    var tintColor: Color {
        switch self {
        case .success: return .green
        case .error: return .red
        case .info: return .blue
        }
    }
}
 
struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
}
