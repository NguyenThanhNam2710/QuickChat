//
//  AuthServiceProtocol.swift
//  QuickChat
//
//  Created by NamNT97 on 21/7/26.
//  Giai đoạn 2 — Authentication
//  Protocol này là "hợp đồng" duy nhất mà ViewModel biết tới — không import FirebaseAuth
//  ở tầng ViewModel/View, đúng nguyên tắc "Services là nơi DUY NHẤT chạm vào Firebase".
//

import Foundation
import AuthenticationServices

protocol AuthServiceProtocol {
    /// Stream trạng thái đăng nhập — bridge từ Firebase addStateDidChangeListener (callback)
    /// sang AsyncStream để dùng async/await, theo đúng nguyên tắc Concurrency trong Roadmap.
    var authStateStream: AsyncStream<User?> { get }
    
    /// Đọc nhanh user hiện tại (đồng bộ), tiện cho các case không cần chờ stream.
    var currentUser: User? { get }
    
    func signUp(email: String, password: String, displayName: String) async throws -> User
    func signIn(email: String, password: String) async throws -> User
    
    /// SwiftUI's SignInWithAppleButton tự quản lý ASAuthorizationController;
    /// Service chỉ nhận kết quả về và hoàn tất việc liên kết với Firebase.
    func completeAppleSignIn(authorization: ASAuthorization, rawNonce: String) async throws -> User
    
    func signInWithGoogle() async throws -> User
    
    func signOut() throws
}
