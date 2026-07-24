//
//  AuthViewModel.swift
//  QuickChat
//
//  Created by NamNT97 on 21/7/26.
//

import Foundation
import Observation
import AuthenticationServices

@Observable
@MainActor
final class AuthViewModel {
#if DEBUG
    var email: String = "dev@gmail.com"
    var password: String = "12345aA@"
#else
    var email: String = ""
    var password: String = ""
#endif
    var confirmPassword: String = ""
    var displayName: String = ""
    var isLoading: Bool = false
    var errorMessage: String?
    
    var didSignUpSuccessfully = false
    
    private let authService: AuthServiceProtocol
    private var currentAppleNonce: String?
    
    var keepSignedIn: Bool = UserDefaults.standard.object(forKey: Constants.UserDefaultsKeys.keepSignedIn) as? Bool ?? true
    
    init(authService: AuthServiceProtocol) {
        self.authService = authService
    }
    
    var isLoginFormValid: Bool {
        Validators.isValidEmail(email) && !password.isEmpty
    }
    
    var isSignUpFormValid: Bool {
        Validators.isValidEmail(email)
        && Validators.isValidPassword(password)
        && password == confirmPassword
        && !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    // MARK: - Email/ Password
    
    func signIn() async {
        guard isLoginFormValid else {
            errorMessage = L10n.Auth.invalidFormError
            return
        }
        await perform { try await self.authService.signIn(email: self.email, password: self.password) }
    }
    
    func signUp() async {
        guard isSignUpFormValid else {
            errorMessage = password != confirmPassword
            ? L10n.Common.passwordMismatch
            : AuthError.weakPassword.localizedDescription
            return
        }
        let success = await perform {
            try await self.authService.signUp(email: self.email, password: self.password, displayName: self.displayName)
        }
        if success {
            didSignUpSuccessfully = true
        }
    }
    
    // MARK: - Sign in with Apple
    // SwiftUI's SignInWithAppleButton tự hiển thị + trigger ASAuthorizationController.
    // ViewModel chỉ cần chuẩn bị request (nonce) và xử lý kết quả trả về.
    
    func prepareAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = CryptoUtils.randomNonceString()
        currentAppleNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = CryptoUtils.sha256(nonce)
    }
    
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            guard let nonce = currentAppleNonce else {
                errorMessage = AuthError.appleSignInFailed.localizedDescription
                return
            }
            await perform {
                try await self.authService.completeAppleSignIn(authorization: authorization, rawNonce: nonce)
            }
        case .failure(let error):
            // Người dùng bấm Cancel không tính là lỗi cần hiển thị.
            if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                return
            }
            errorMessage = AuthError.appleSignInFailed.localizedDescription
        }
    }
    
    // MARK: - Sign in with Google
    
    func signInWithGoole() async {
        await perform {
            try await self.authService.signInWithGoogle()
        }
    }
    
    // MARK: - Shared
    
    @discardableResult
    private func perform(_ action: @escaping () async throws -> User) async -> Bool {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false}
        do {
            _ = try await action()
            UserDefaults.standard.set(keepSignedIn, forKey: Constants.UserDefaultsKeys.keepSignedIn)
            return true
        } catch {
            errorMessage = (error as? AuthError)?.localizedDescription ?? error.localizedDescription
            return false
        }
    }
}
