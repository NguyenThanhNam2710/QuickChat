//
//  String+Clipboard.swift
//  QuickChat
//
//  Created by NamNT97 on 29/7/26.
//  Copy text đa nền tảng — UIPasteboard (iOS/iPadOS/visionOS) vs NSPasteboard (macOS).
//

import Foundation

#if os(macOS)
import AppKit
#else
import UIKit
#endif

func copyToPasteboard(_ text: String) {
    #if os(macOS)
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(text, forType: .string)
    #else
    UIPasteboard.general.string = text
    #endif
}
