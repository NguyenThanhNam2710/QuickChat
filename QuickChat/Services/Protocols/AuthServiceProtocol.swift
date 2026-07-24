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
    
    /// Danh sách provider đã liên kết với tài khoản hiện tại (vd "password", "apple.com", "google.com").
    /// Dùng để quyết định có hiển thị phần "Đổi mật khẩu" hay không.
    var signInProviders: [String] { get }
    
    func signUp(email: String, password: String, displayName: String) async throws -> User
    func signIn(email: String, password: String) async throws -> User
    
    /// SwiftUI's SignInWithAppleButton tự quản lý ASAuthorizationController;
    /// Service chỉ nhận kết quả về và hoàn tất việc liên kết với Firebase.
    func completeAppleSignIn(authorization: ASAuthorization, rawNonce: String) async throws -> User
    
    func signInWithGoogle() async throws -> User
    
    func signOut() throws
    
    /// Sửa tên hiển thị trên Firebase Auth, trả về User đã cập nhật để caller tự sync xuống Firestore.
    func updateDisplayName(_ displayName: String) async throws -> User
    
    /// Đổi mật khẩu — tự động reauthenticate bằng mật khẩu hiện tại trước khi đổi.
    /// Chỉ áp dụng cho tài khoản có provider "password".
    func updatePassword(currentPassword: String, newPassword: String) async throws
    
}
