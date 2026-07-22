//
//  String+Mask.swift
//  QuickChat
//
//  Created by NamNT97 on 22/7/26.
//

import Foundation

extension String {
    
    func maskedEmail() -> String {
        guard let atIndex = firstIndex(of: "@") else { return "***"}
        let name = self[..<atIndex]
        let domain = self[atIndex...]
        guard name.count > 2  else { return "***" + domain }
        return "\(name.prefix(2))***\(domain))"
    }
}
