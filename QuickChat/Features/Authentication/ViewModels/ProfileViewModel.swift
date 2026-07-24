//
//  ProfileViewModel.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import Foundation
import Observation

@Observable
@MainActor
final class ProfileViewModel {
    var displayName: String
    var currentPassword: String = ""
    var newPassword: String = ""
    var confirmNewPassword: String = ""

    private(set) var isSavingName = false
    private(set) var isSavingPassword = false
    var nameErrorMessage: String?
    var passwordErrorMessage: String?
    var didUpdateName = false
    var didUpdatePassword = false

    /// Chỉ hiển thị phần đổi mật khẩu nếu tài khoản đăng nhập bằng email/password —
    /// tài khoản Apple/Google không có mật khẩu trong hệ thống Firebase.
    let canChangePassword: Bool
    let email: String

    private let authService: AuthServiceProtocol
    private let userService: UserServiceProtocol

    init(authService: AuthServiceProtocol, userService: UserServiceProtocol) {
        self.authService = authService
        self.userService = userService
        self.displayName = authService.currentUser?.displayName ?? ""
        self.email = authService.currentUser?.email ?? ""
        self.canChangePassword = authService.signInProviders.contains("password")
    }

    // MARK: - Đổi tên

    var isNameValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func saveDisplayName() async {
        guard isNameValid else {
            nameErrorMessage = L10n.Profile.emptyNameError
            return
        }
        isSavingName = true
        nameErrorMessage = nil
        didUpdateName = false
        defer { isSavingName = false }

        do {
            let trimmed = displayName.trimmingCharacters(in: .whitespaces)
            let user = try await authService.updateDisplayName(trimmed)
            // Đồng bộ ngay xuống Firestore — authStateStream KHÔNG tự bắn lại khi chỉ đổi profile,
            // nên phải tự gọi ở đây, không thì users/{uid}.displayName trên Firestore sẽ đứng yên.
            try await userService.syncCurrentUserProfile(user)
            didUpdateName = true
        } catch {
            nameErrorMessage = (error as? AuthError)?.localizedDescription ?? error.localizedDescription
        }
    }

    // MARK: - Đổi mật khẩu

    var isPasswordFormValid: Bool {
        !currentPassword.isEmpty
        && Validators.isValidPassword(newPassword)
        && newPassword == confirmNewPassword
    }

    func savePassword() async {
        guard isPasswordFormValid else {
            passwordErrorMessage = newPassword != confirmNewPassword
                ? L10n.Common.passwordMismatch
                : AuthError.weakPassword.localizedDescription
            return
        }
        isSavingPassword = true
        passwordErrorMessage = nil
        didUpdatePassword = false
        defer { isSavingPassword = false }

        do {
            try await authService.updatePassword(currentPassword: currentPassword, newPassword: newPassword)
            didUpdatePassword = true
            currentPassword = ""
            newPassword = ""
            confirmNewPassword = ""
        } catch let error as AuthError {
            // Firebase trả cùng mã lỗi cho "sai mật khẩu hiện tại" — đổi message cho đúng ngữ cảnh.
            passwordErrorMessage = (error == .wrongPassword) ? AuthError.wrongCurrentPassword.localizedDescription : error.localizedDescription
        } catch {
            passwordErrorMessage = error.localizedDescription
        }
    }
}
