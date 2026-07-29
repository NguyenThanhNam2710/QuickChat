//
//  L10n.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import Foundation

private func t(_ key: String, _ defaultValue: String) -> String {
    LocalizationManager.shared.string(key, defaultValue: defaultValue)
}

enum L10n {
    
    enum Common {
        static var cancel: String { t("common.cancel", "Hủy") }
        static var confirm: String { t("common.confirm", "Xác nhận") }
        static var loading: String { t("common.loading", "Đang tải...") }
        static var email: String { t("common.email", "Email") }
        static var passwordMismatch: String { t("common.passwordMismatch", "Mật khẩu xác nhận không khớp.") }
        static var offlineBanner: String { t("common.offlineBanner", "Mất kết nối mạng") }
    }
    
    enum DateTime {
        static var justNow: String { t("chatTime.justNow", "Vừa xong") }
        static var yesterday: String { t("chatTime.yesterday", "Hôm qua") }
    }
    
    enum Auth {
        static var loginSubtitle: String { t("auth.login.subtitle", "Đăng nhập để tiếp tục") }
        static var passwordPlaceholder: String { t("auth.login.passwordPlaceholder", "Mật khẩu") }
        static var signInButton: String { t("auth.login.signInButton", "Đăng nhập") }
        static var orDivider: String { t("auth.login.orDivider", "hoặc") }
        static var googleButton: String { t("auth.login.googleButton", "Đăng nhập với Google") }
        static var goToSignUp: String { t("auth.login.goToSignUp", "Chưa có tài khoản? Đăng ký") }
        static var keepSignedIn: String { t("auth.login.keepSignedIn", "Duy trì đăng nhập trên thiết bị này") }
        static var invalidFormError: String { t("auth.login.invalidFormError", "Vui lòng nhập email hợp lệ và mật khẩu.") }
        
        static var signUpTitle: String { t("auth.signUp.title", "Đăng ký") }
        static var displayNamePlaceholder: String { t("auth.signUp.displayNamePlaceholder", "Tên hiển thị") }
        static var signUpPasswordPlaceholder: String { t("auth.signUp.passwordPlaceholder", "Mật khẩu (≥8 ký tự, có chữ hoa & số)") }
        static var confirmPasswordPlaceholder: String { t("auth.signUp.confirmPasswordPlaceholder", "Xác nhận mật khẩu") }
        static var signUpButton: String { t("auth.signUp.submitButton", "Tạo tài khoản") }
        static var signUpSuccessToast: String { t("auth.signUp.successToast", "Tạo tài khoản thành công!") }
    }
    
    enum AuthError {
        static var invalidEmail: String { t("authError.invalidEmail", "Email không hợp lệ.") }
        static func weakPassword(minLength: Int) -> String {
            String(format: t("authError.weakPasswordFormat", "Mật khẩu cần tối thiểu %d ký tự, có ít nhất 1 chữ hoa và 1 chữ số."), minLength)
        }
        static var emailAlreadyInUse: String { t("authError.emailAlreadyInUse", "Email này đã được đăng ký.") }
        static var wrongPassword: String { t("authError.wrongPassword", "Sai email hoặc mật khẩu.") }
        static var wrongCurrentPassword: String { t("authError.wrongCurrentPassword", "Mật khẩu hiện tại không đúng.") }
        static var userNotFound: String { t("authError.userNotFound", "Tài khoản không tồn tại.") }
        static var network: String { t("authError.network", "Lỗi kết nối mạng. Vui lòng thử lại.") }
        static var appleSignInFailed: String { t("authError.appleSignInFailed", "Đăng nhập với Apple thất bại. Vui lòng thử lại.") }
        static var googleSignInFailed: String { t("authError.googleSignInFailed", "Đăng nhập với Google thất bại. Vui lòng thử lại.") }
        static var googleClientIDMissing: String { t("authError.googleClientIDMissing", "Chưa cấu hình Google Sign-In cho project này (thiếu CLIENT_ID trong GoogleService-Info.plist).") }
    }
    
    enum Root {
        static var signOutTitle: String { t("root.signOutTitle", "Đăng xuất") }
        static var signOutMessage: String { t("root.signOutMessage", "Bạn có chắc muốn đăng xuất khỏi QuickChat?") }
    }
    
    enum ConversationList {
        static var title: String { t("conversationList.title", "Trò chuyện") }
        static var emptyTitle: String { t("conversationList.emptyTitle", "Chưa có cuộc trò chuyện") }
        static var emptyDescription: String { t("conversationList.emptyDescription", "Bắt đầu trò chuyện mới để xem tại đây.") }
        static var unknownUser: String { t("conversationList.unknownUser", "Người dùng ẩn danh") }
        static var noMessageYet: String { t("conversationList.noMessageYet", "Chưa có tin nhắn nào") }
    }
    
    enum NewConversation {
        static var title: String { t("newConversation.title", "Trò chuyện mới") }
        static var searchSectionHeader: String { t("newConversation.searchSectionHeader", "Tìm người dùng theo email") }
        static var emailPlaceholder: String { t("newConversation.emailPlaceholder", "vd: ban@gmail.com") }
        static var searchButton: String { t("newConversation.searchButton", "Tìm") }
        static var resultSectionHeader: String { t("newConversation.resultSectionHeader", "Kết quả") }
        static var unknownName: String { t("newConversation.unknownName", "Không rõ tên") }
        static var startChatButton: String { t("newConversation.startChatButton", "Nhắn tin") }
        static var userNotFound: String { t("newConversation.userNotFound", "Không tìm thấy người dùng với email này.") }
        static var cannotChatWithSelf: String { t("newConversation.cannotChatWithSelf", "Không thể tạo cuộc trò chuyện với chính mình.") }
        static func searchError(_ message: String) -> String {
            String(format: t("newConversation.searchErrorFormat", "Lỗi tìm kiếm: %@"), message)
        }
        static func createError(_ message: String) -> String {
            String(format: t("newConversation.createErrorFormat", "Không thể tạo cuộc trò chuyện: %@"), message)
        }
    }
    
    enum Profile {
        static var title: String { t("profile.title", "Thông tin cá nhân") }
        static var accountSectionHeader: String { t("profile.accountSectionHeader", "Tài khoản") }
        static var displayNameSectionHeader: String { t("profile.displayNameSectionHeader", "Tên hiển thị") }
        static var saveNameButton: String { t("profile.saveNameButton", "Lưu tên") }
        static var changePasswordSectionHeader: String { t("profile.changePasswordSectionHeader", "Đổi mật khẩu") }
        static var currentPasswordPlaceholder: String { t("profile.currentPasswordPlaceholder", "Mật khẩu hiện tại") }
        static var newPasswordPlaceholder: String { t("profile.newPasswordPlaceholder", "Mật khẩu mới (≥8 ký tự, có chữ hoa & số)") }
        static var confirmNewPasswordPlaceholder: String { t("profile.confirmNewPasswordPlaceholder", "Xác nhận mật khẩu mới") }
        static var noPasswordNote: String { t("profile.noPasswordNote", "Tài khoản của bạn đăng nhập qua Apple/Google, không có mật khẩu để đổi tại đây.") }
        static var nameUpdatedToast: String { t("profile.nameUpdatedToast", "Đã cập nhật tên hiển thị.") }
        static var passwordUpdatedToast: String { t("profile.passwordUpdatedToast", "Đã đổi mật khẩu thành công.") }
        static var emptyNameError: String { t("profile.emptyNameError", "Tên hiển thị không được để trống.") }
        static var settingsSectionHeader: String { t("profile.settingsSectionHeader", "Khác") }
        static var settingsLink: String { t("profile.settingsLink", "Cài đặt") }
    }
    
    enum Settings {
        static var title: String { t("settings.title", "Cài đặt") }
        static var languageSectionHeader: String { t("settings.languageSectionHeader", "Ngôn ngữ") }
        static var languagePickerLabel: String { t("settings.languagePickerLabel", "Chọn ngôn ngữ") }
        static var languageFooter: String { t("settings.languageFooter", "Áp dụng ngay lập tức, không cần khởi động lại ứng dụng.") }
        static var languageSystem: String { t("settings.languageSystem", "Theo hệ thống") }
    }
    
    enum Chat {
        static var title: String { t("chat.title", "Trò chuyện") }
        static var inputPlaceholder: String { t("chat.inputPlaceholder", "Nhập tin nhắn...") }
        static var retrySend: String { t("chat.retrySend", "Gửi lại") }
        static var messageTooLong: String { t("chat.messageTooLong", "Tin nhắn quá dài.") }
        static var reply: String { t("chat.reply", "Trả lời") }
        static var edit: String { t("chat.edit", "Chỉnh sửa") }
        static var recall: String { t("chat.recall", "Thu hồi") }
        static var react: String { t("chat.react", "Thả cảm xúc") }
        static var recalledMessage: String { t("chat.recalledMessage", "Tin nhắn đã được thu hồi") }
        static var editedSuffix: String { t("chat.editedSuffix", "(đã chỉnh sửa)") }
        static var replyToYou: String { t("chat.replyToYou", "Trả lời bạn") }
        static var replyToOther: String { t("chat.replyToOther", "Trả lời") }
        static var replyingToLabel: String { t("chat.replyingToLabel", "Đang trả lời") }
        static var editingLabel: String { t("chat.editingLabel", "Đang chỉnh sửa tin nhắn") }
        static var editWindowExpired: String { t("chat.editWindowExpired", "Chỉ có thể chỉnh sửa tin nhắn trong vòng 30 phút sau khi gửi.") }
        static var recallWindowExpired: String { t("chat.recallWindowExpired", "Chỉ có thể thu hồi tin nhắn trong vòng 15 phút sau khi gửi.") }
        static var copyText: String { t("chat.copyText", "Sao chép") }
        static var copiedToast: String { t("chat.copiedToast", "Đã sao chép") }
    }
}
