//
//  Date+Ext.swift
//  QuickChat
//
//  Created by NamNT97 on 23/7/26.
//

import Foundation

extension Date {
    
    func chatTimeText() -> String {
        let now = Date()
        let calendar = Calendar.current
        let secondsAgo = now.timeIntervalSince(self)
        
        if secondsAgo < 60 {
            return L10n.DateTime.justNow
        } else if calendar.isDateInToday(self) {
            return self.formatted(.dateTime.hour().minute())
        } else if calendar.isDateInYesterday(self) {
            return L10n.DateTime.yesterday
        } else if secondsAgo < 7 * 24 * 3600 {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE"
            formatter.locale = Locale.current
            return formatter.string(from: self).capitalized
        } else {
            return self.formatted(.dateTime.day().month().year(.twoDigits))
        }
    }
}
