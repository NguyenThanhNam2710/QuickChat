//
//  MessageActionContext.swift
//  QuickChat
//
//  Created by NamNT97 on 29/7/26.
//  State cho biết bubble nào đang được "focus" trong MessageActionOverlay
//  và toạ độ global của nó tại thời điểm long-press (dùng để đặt overlay đúng vị trí).
//

import Foundation

struct MessageActionContext: Identifiable {
    let item: ChatMessageItem
    let frame: CGRect
    let isOutgoing: Bool
    var id: String { item.id }
}
