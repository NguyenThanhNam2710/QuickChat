//
//  AuthService.swift
//  QuickChat
//
//  Created by NamNT97 on 21/7/26.
//  Giai đoạn 2 — Authentication
//  Đây là nơi DUY NHẤT trong app "chạm" vào FirebaseAuth / GoogleSignIn.
//  Nếu sau này đổi backend, chỉ cần viết lại file này (và AuthServiceProtocol nếu cần đổi API).
//

import Foundation
import FirebaseCore
import FirebaseAuth
import AuthenticationServices

#if os(iOS)
import GoogleSignIn
import UIKit
#endif

final class AuthService: AuthServiceProtocol {
    private let auth = Auth.auth()
    
    var currentUser: User? {
        auth.currentUser.map(Self.mapFirebaseUser)
    }
    
    // MARK: - Auth State Stream
    var authStateStream: AsyncStream<User?> {
        AsyncStream { continuation in
            let handle = auth.addStateDidChangeListener { _, firebaseUser in
                if let firebaseUser {
                    AppLogger.auth.info("authStateDidChange → signedIn (uid: \(firebaseUser.uid, privacy: .public))")
                } else {
                    AppLogger.auth.info("authStateDidChange → signedOut")
                }
                continuation.yield(firebaseUser.map(Self.mapFirebaseUser))
            }
            continuation.onTermination = { [auth] _ in
                auth.removeStateDidChangeListener(handle)
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws -> User {
        try await AppLogger.auth.logCall(
            "signUp",
            header: ["sdk": "FirebaseAuth", "provider": "password"],
            body: ["email": email.maskedEmail(), "password": "••••••••", "displayName": displayName],
            response: { user in ["uid": user.id, "email": user.email ?? "nil", "displayName": user.displayName ?? "nil"] }
        ) {
            do {
                let result = try await auth.createUser(withEmail: email, password: password)
                let changeRequest = result.user.createProfileChangeRequest()
                changeRequest.displayName = displayName
                try await changeRequest.commitChanges()
                return Self.mapFirebaseUser(result.user, overrideDisplayName: displayName)
            } catch {
                throw AuthError.map(error)
            }
        }
    }
    
    func signIn(email: String, password: String) async throws -> User {
        try await AppLogger.auth.logCall(
            "signIn",
            header: ["sdk": "FirebaseAuth", "provider": "password"],
            body: ["email": email.maskedEmail(), "password": "••••••••"],
            response: { user in ["uid": user.id, "email": user.email ?? "nil", "displayName": user.displayName ?? "nil"] }
        ) {
            do {
                let result = try await auth.signIn(withEmail: email, password: password)
                return Self.mapFirebaseUser(result.user)
            } catch {
                throw AuthError.map(error)
            }
        }
    }
    
    func signOut() throws {
        AppLogger.auth.info("┌─ → signOut  header: {\"sdk\": \"FirebaseAuth\"}")
        do {
            try auth.signOut()
#if os(iOS)
            GIDSignIn.sharedInstance.signOut()
#endif
            AppLogger.auth.info("└─ ✓ signOut thành công")
        } catch {
            AppLogger.auth.error("└─ ✗ signOut thất bại — \(error.localizedDescription, privacy: .public)")
            throw AuthError.map(error)
        }
    }
    
    // MARK: - Sign in with Apple
    func completeAppleSignIn(authorization: ASAuthorization, rawNonce: String) async throws -> User {
        try await AppLogger.auth.logCall(
            "completeAppleSignIn",
            header: ["sdk": "FirebaseAuth", "provider": "apple.com"],
            body: ["hasIdentityToken": (authorization.credential as? ASAuthorizationAppleIDCredential)?.identityToken != nil],
            response: { user in ["uid": user.id, "email": user.email ?? "nil", "displayName": user.displayName ?? "nil"] }
        ) {
            guard
                let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let identityToken = appleIDCredential.identityToken,
                let idTokenString = String(data: identityToken, encoding: .utf8)
            else {
                throw AuthError.appleSignInFailed
            }
            
            let credential = OAuthProvider.appleCredential(
                withIDToken: idTokenString,
                rawNonce: rawNonce,
                fullName: appleIDCredential.fullName
            )
            
            do {
                let result = try await auth.signIn(with: credential)
                
                // Apple chỉ trả về fullName ở LẦN ĐẦU đăng nhập, nên cần lưu lại vào displayName ngay.
                var displayName = result.user.displayName
                if (displayName?.isEmpty ?? true), let fullName = appleIDCredential.fullName {
                    let formatted = PersonNameComponentsFormatter().string(from: fullName)
                    if !formatted.isEmpty {
                        let changeRequest = result.user.createProfileChangeRequest()
                        changeRequest.displayName = formatted
                        try? await changeRequest.commitChanges()
                        displayName = formatted
                    }
                }
                return Self.mapFirebaseUser(result.user, overrideDisplayName: displayName)
            } catch {
                throw AuthError.map(error)
            }
        }
    }
    
    // MARK: - Sign in with Google
    @MainActor
    func signInWithGoogle() async throws -> User {
        try await AppLogger.auth.logCall(
            "signInWithGoogle",
            header: ["sdk": "GoogleSignIn + FirebaseAuth", "provider": "google.com"],
            response: { user in ["uid": user.id, "email": user.email ?? "nil", "displayName": user.displayName ?? "nil"] }
        ) {
#if os(iOS)
            guard let clientID = FirebaseApp.app()?.options.clientID else {
                throw AuthError.googleClientIDMissing
            }
            GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: clientID)
            
            guard let rootViewController = await MainActor.run(body: { Self.rootViewController() }) else {
                throw AuthError.googleSignInFailed
            }
            
            do {
                let signInResult = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
                guard let idToken = signInResult.user.idToken?.tokenString else {
                    throw AuthError.googleSignInFailed
                }
                let credential = GoogleAuthProvider.credential(
                    withIDToken: idToken,
                    accessToken: signInResult.user.accessToken.tokenString)
                let authResult = try await auth.signIn(with: credential)
                return Self.mapFirebaseUser(authResult.user)
            } catch {
                throw AuthError.map(error)
            }
#else
            // Google Sign-In trong bản này chỉ hỗ trợ iOS/iPadOS.
            // macOS/visionOS cần luồng riêng (ASWebAuthenticationSession) — để TODO cho giai đoạn sau.
            throw AuthError.googleSignInFailed
#endif
        }
    }
    
#if os(iOS)
    @MainActor
    private static func rootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?
            .rootViewController
    }
#endif
    
    // MARK: - Mapping
    private static func mapFirebaseUser(_ firebaseUser: FirebaseAuth.User, overrideDisplayName: String? = nil) -> User {
        User(
            id: firebaseUser.uid,
            email: firebaseUser.email,
            displayName: overrideDisplayName ?? firebaseUser.displayName,
            avatarURL: firebaseUser.photoURL?.absoluteString,
            lastSeen: Date()
        )
    }
    
    private static func mapFirebaseUser(_ firebaseUser: FirebaseAuth.User) -> User {
        mapFirebaseUser(firebaseUser, overrideDisplayName: nil)
    }
}
