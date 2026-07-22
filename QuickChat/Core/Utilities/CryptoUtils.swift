//
//  Validators.swift
//  QuickChat
//
//  Created by NamNT97 on 21/7/26.
//  Cần cho luồng Sign in with Apple (nonce chống replay-attack)

import Foundation
import CryptoKit

enum CryptoUtils {
    /// Sinh chuỗi ngẫu nhiên an toàn để làm nonce.
    static func randomNonceString(lenght: Int = 32) -> String {
        precondition(lenght > 0)
        var randomBytes = [UInt8](repeating: 0, count: lenght)
        let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if status != errSecSuccess {
            fatalError("Không thể sinh nonce ngẫu nhiên (SecRandomCopyBytes status: \(status)).")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }
    
    /// SHA256 dùng để hash nonce trước khi gửi cho Apple (Apple yêu cầu nonce đã hash trong request).
    static func sha256(_ intput: String) -> String {
        let hashed = SHA256.hash(data: Data(intput.utf8))
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
