//
//  UserServiceProtocol.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import Foundation

protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User?
    
    /// Ghi/merge profile hiện tại lên Firestore users/{uid}. Gọi mỗi khi authStateStream
    /// phát ra user đã đăng nhập (xem AppState.observeAuthState).
    func syncCurrentUserProfile(_ user: User) async throws
    
    /// Tìm user theo email chính xác — dùng cho màn "Tạo cuộc trò chuyện mới".
    func fetchUser(byEmail email: String) async throws -> User?
}
