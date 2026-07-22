//
//  AppAlert.swift
//  QuickChat
//
//  Created by NamNT97 on 22/7/26.
//

import Foundation
 
struct AppAlert: Identifiable {
    let id = UUID()
    let title: String
    var message: String?
    var primaryButtonTitle: String = "OK"
    var primaryAction: (() -> Void)?
    var isDestructive: Bool = false
    var secondaryButtonTitle: String?
}
