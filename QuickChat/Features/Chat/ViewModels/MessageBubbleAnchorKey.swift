//
//  MessageBubbleAnchorKey.swift
//  QuickChat
//
//  Created by NamNT97 on 29/7/26.
//  PreferenceKey dạng Anchor<CGRect> — thay thế cách đo frame cũ bằng
//  GeometryReader lồng trong .background() (không đáng tin cậy trong LazyVStack/ScrollView,
//  hay trả về .zero do layout lazy). Anchor được SwiftUI quản lý qua hệ thống riêng,
//  chỉ cần resolve bằng GeometryProxy ở tầng cha (geo[anchor]) — đáng tin cậy hơn hẳn.
//

import SwiftUI

struct MessageBubbleAnchorKey: PreferenceKey {
    static var defaultValue: [String: Anchor<CGRect>] = [:]
    static func reduce(value: inout [String: Anchor<CGRect>], nextValue: () -> [String: Anchor<CGRect>]) {
        value.merge(nextValue(), uniquingKeysWith: { _, new in new })
    }
}
