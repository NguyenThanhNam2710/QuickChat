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
        static let minPasswordLength = 6
    }

    enum Pagination {
        static let messagesPageSize = 30
    }
}
