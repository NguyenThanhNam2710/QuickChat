//
//  User.swift
//  QuickChat
//
//  Created by NamNT97 on 21/7/26.
//

import Foundation

struct User: Identifiable, Codable, Equatable {
    let id: String
    var email: String?
    var displayName: String?
    var avatarURL: String?
    var lastSeen: Date?
}
