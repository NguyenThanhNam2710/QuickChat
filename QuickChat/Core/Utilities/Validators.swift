//
//  Validators.swift
//  QuickChat
//
//  Created by NamNT97 on 21/7/26.
//

import Foundation

enum Validators {
    static func isValidEmail(_ email: String) -> Bool {
        NSPredicate(format: "SELF MATCHES %@", Constants.Validation.emailRegex).evaluate(with: email)
    }
    
    static func isValidPassword(_ password: String) -> Bool {
        NSPredicate(format: "SELF MATCHES %@", Constants.Validation.passwordRegex).evaluate(with: password)
    }
}
