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
    case wrongCurrentPassword
    case userNotFound
    case network
    case appleSignInFailed
    case googleSignInFailed
    case googleClientIDMissing
    case unknown(String)

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return L10n.AuthError.invalidEmail
        case .weakPassword: return L10n.AuthError.weakPassword(minLength: Constants.Validation.minPasswordLength)
        case .emailAlreadyInUse: return L10n.AuthError.emailAlreadyInUse
        case .wrongPassword: return L10n.AuthError.wrongPassword
        case .wrongCurrentPassword: return L10n.AuthError.wrongCurrentPassword
        case .userNotFound: return L10n.AuthError.userNotFound
        case .network: return L10n.AuthError.network
        case .appleSignInFailed: return L10n.AuthError.appleSignInFailed
        case .googleSignInFailed: return L10n.AuthError.googleSignInFailed
        case .googleClientIDMissing: return L10n.AuthError.googleClientIDMissing
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
