//
//  AuthError.swift
//  QuickChat
//
//  Created by NamNT97 on 21/7/26.
//

import Foundation
import FirebaseAuth

enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case wrongPassword
    case userNotFound
    case network
    case appleSignInFailed
    case googleSignInFailed
    case googleClientIDMissing
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Email không hợp lệ."
        case .weakPassword: return "Mật khẩu cần tối thiểu \(Constants.Validation.minPasswordLength) ký tự, có ít nhất 1 chữ hoa và 1 chữ số."
        case .emailAlreadyInUse: return "Email này đã được đăng ký."
        case .wrongPassword: return "Sai email hoặc mật khẩu."
        case .userNotFound: return "Tài khoản không tồn tại."
        case .network: return "Lỗi kết nối mạng. Vui lòng thử lại."
        case .appleSignInFailed: return "Đăng nhập với Apple thất bại. Vui lòng thử lại."
        case .googleSignInFailed: return "Đăng nhập với Google thất bại. Vui lòng thử lại."
        case .googleClientIDMissing: return "Chưa cấu hình Google Sign-In cho project này (thiếu CLIENT_ID trong GoogleService-Info.plist)."
        case .unknown(let message): return message
        }
    }
    
    static func map(_ error: Error) -> AuthError {
        let nsError = error as NSError
        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return .unknown(nsError.localizedDescription)
        }
        switch code {
        case .invalidEmail: return .invalidEmail
        case .weakPassword: return .weakPassword
        case .emailAlreadyInUse: return .emailAlreadyInUse
        case .wrongPassword, .invalidCredential: return .wrongPassword
        case .userNotFound: return .userNotFound
        case .networkError: return .network
        default: return .unknown(nsError.localizedDescription)
        }
    }
}
