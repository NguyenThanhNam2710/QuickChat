//
//  Constants.swift
//  QuickChat
//
//  Created by NamNT97 on 20/7/26.
//

import Foundation

enum Constants {
    
    enum Firestore {
        static let usersCollection = "users"
        static let conversationsCollection = "conversations"
        static let messagesSubcollectionName = "items"
    }
    
    enum Validation {
        static let minPasswordLength = 8
        static let passwordRegex = "^(?=.*[A-Z])(?=.*[0-9]).{8,}$"
        static let emailRegex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        static let maxMessageLength = 2000
    }
    
    enum Pagination {
        static let messagesPageSize = 30
    }
    
    enum UserDefaultsKeys {
        static let keepSignedIn = "keepSignedIn"
    }
}
