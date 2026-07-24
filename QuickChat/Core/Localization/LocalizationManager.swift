//
//  LocalizationManager.swift
//  QuickChat
//
//  Created by NamNT97 on 24/7/26.
//

import Foundation
import Observation

@Observable
final class LocalizationManager {
    /// Singleton — vì cả app chỉ nên có 1 nguồn sự thật cho ngôn ngữ đang chọn.
    static let shared = LocalizationManager()

    private static let storageKey = "selectedAppLanguage"

    var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: Self.storageKey)
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.storageKey)
        currentLanguage = saved.flatMap(AppLanguage.init(rawValue:)) ?? .system
    }

    /// Bundle tương ứng ngôn ngữ đang chọn. `.system` → trả về Bundle.main (tự theo máy).
    /// Với vi/en → tự tìm thư mục "vi.lproj"/"en.lproj" mà Xcode đã build sẵn từ
    /// Localizable.xcstrings, rồi đọc trực tiếp từ đó — đây là phần "lách" cơ chế mặc định.
    private var activeBundle: Bundle {
        guard currentLanguage != .system else { return .main }
        guard
            let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            AppLogger.ui.error("Không tìm thấy \(self.currentLanguage.rawValue, privacy: .public).lproj — đã khai báo Localizations ở Project Settings chưa?")
            return .main
        }
        return bundle
    }

    /// Hàm tra cứu duy nhất mà L10n.swift sẽ gọi — thay thế cho String(localized:defaultValue:).
    func string(_ key: String, defaultValue: String) -> String {
        activeBundle.localizedString(forKey: key, value: defaultValue, table: "Localizable")
    }
}
