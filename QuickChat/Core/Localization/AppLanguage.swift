//
//  AppLanguage.swift
//  QuickChat
//
//  Created by NamNT97 on 24/7/26.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    /// Không ép ngôn ngữ — dùng theo Preferred Languages của hệ thống (mặc định).
    case system
    case vietnamese = "vi"
    case english = "en"

    var id: String { rawValue }

    /// Tên hiển thị trong Picker — CỐ Ý không đưa qua L10n: tên 1 ngôn ngữ nên luôn hiển thị
    /// bằng chính ngôn ngữ đó (giống cách iOS Settings hiển thị "Tiếng Việt"/"English"),
    /// không dịch theo ngôn ngữ đang chọn.
    var displayName: String {
        switch self {
        case .system: return L10n.Settings.languageSystem
        case .vietnamese: return "Tiếng Việt"
        case .english: return "English"
        }
    }
}
