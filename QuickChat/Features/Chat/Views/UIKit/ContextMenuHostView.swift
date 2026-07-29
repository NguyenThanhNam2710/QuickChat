//
//  ContextMenuHostView.swift
//  QuickChat
//
//  Created by NamNT97 on 29/7/26.
//  UIView trong suốt, chỉ mang 1 UIContextMenuInteraction — cầu nối để dùng
//  UIMenu.preferredElementSize = .small (hàng icon ngang, trượt được nếu quá dài)
//  vốn KHÔNG có API tương đương trong SwiftUI .contextMenu thuần.
//  Chỉ dùng trên iOS/iPadOS — UIKit không tồn tại trên AppKit (macOS).
//

#if os(iOS)
import UIKit

final class ContextMenuHostView: UIView {
    /// Trả về configuration cho menu — được gọi lại MỖI LẦN long-press, nên luôn
    /// phản ánh state mới nhất (không lo bị "đứng hình" dữ liệu cũ).
    var configurationProvider: ((CGPoint) -> UIContextMenuConfiguration?)?

    private lazy var contextMenuInteraction = UIContextMenuInteraction(delegate: self)

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addInteraction(contextMenuInteraction)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ContextMenuHostView: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(
        _ interaction: UIContextMenuInteraction,
        configurationForMenuAtLocation location: CGPoint
    ) -> UIContextMenuConfiguration? {
        configurationProvider?(location)
    }
}
#endif
