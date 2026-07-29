//
//  MessageContextMenuOverlay.swift
//  QuickChat
//
//  Created by NamNT97 on 29/7/26.
//  Bridge SwiftUI ↔ UIKit — gắn UIContextMenuInteraction lên trên bubble, cho phép
//  dùng UIMenu.preferredElementSize = .small (hàng emoji NGANG, tự trượt nếu quá dài) —
//  đúng API Apice dùng cho Mail flag-color picker / Reminders tag picker.
//  Chỉ dùng trên iOS/iPadOS.
//

#if os(iOS)
import SwiftUI
import UIKit

struct MessageContextMenuOverlay: UIViewRepresentable {
    let message: Message
    let isOutgoing: Bool
    let currentUserID: String
    let onReply: () -> Void
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onRecall: () -> Void
    let onReact: (String) -> Void

    func makeUIView(context: Context) -> ContextMenuHostView {
        let view = ContextMenuHostView()
        // [weak view] để tránh retain cycle: view giữ closure, closure giữ view.
        view.configurationProvider = { [weak view, coordinator = context.coordinator] _ in
            coordinator.makeConfiguration(hostSize: view?.bounds.size ?? .zero)
        }
        return view
    }

    func updateUIView(_ uiView: ContextMenuHostView, context: Context) {
        context.coordinator.update(
            message: message, isOutgoing: isOutgoing, currentUserID: currentUserID,
            onReply: onReply, onCopy: onCopy, onEdit: onEdit, onRecall: onRecall, onReact: onReact
        )
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(
            message: message, isOutgoing: isOutgoing, currentUserID: currentUserID,
            onReply: onReply, onCopy: onCopy, onEdit: onEdit, onRecall: onRecall, onReact: onReact
        )
    }

    final class Coordinator {
        private var message: Message
        private var isOutgoing: Bool
        private var currentUserID: String
        private var onReply: () -> Void
        private var onCopy: () -> Void
        private var onEdit: () -> Void
        private var onRecall: () -> Void
        private var onReact: (String) -> Void

        init(
            message: Message, isOutgoing: Bool, currentUserID: String,
            onReply: @escaping () -> Void, onCopy: @escaping () -> Void,
            onEdit: @escaping () -> Void, onRecall: @escaping () -> Void,
            onReact: @escaping (String) -> Void
        ) {
            self.message = message
            self.isOutgoing = isOutgoing
            self.currentUserID = currentUserID
            self.onReply = onReply
            self.onCopy = onCopy
            self.onEdit = onEdit
            self.onRecall = onRecall
            self.onReact = onReact
        }

        func update(
            message: Message, isOutgoing: Bool, currentUserID: String,
            onReply: @escaping () -> Void, onCopy: @escaping () -> Void,
            onEdit: @escaping () -> Void, onRecall: @escaping () -> Void,
            onReact: @escaping (String) -> Void
        ) {
            self.message = message
            self.isOutgoing = isOutgoing
            self.currentUserID = currentUserID
            self.onReply = onReply
            self.onCopy = onCopy
            self.onEdit = onEdit
            self.onRecall = onRecall
            self.onReact = onReact
        }

        func makeConfiguration(hostSize: CGSize) -> UIContextMenuConfiguration? {
            guard !message.isRecalled else { return nil }

            // Size preview KHỚP đúng kích thước bubble thật (host view = overlay trên
            // MessageBubbleContentView) — giúp animation "nhấc lên" mượt, không bị giật.
            let previewSize = (hostSize.width > 0 && hostSize.height > 0) ? hostSize : CGSize(width: 200, height: 60)
            let previewMessage = message
            let previewIsOutgoing = isOutgoing
            let previewCurrentUserID = currentUserID

            return UIContextMenuConfiguration(identifier: nil, previewProvider: {
                let host = UIHostingController(
                    rootView: MessageBubbleContentView(
                        message: previewMessage,
                        isOutgoing: previewIsOutgoing,
                        currentUserID: previewCurrentUserID
                    )
                )
                host.view.backgroundColor = .clear
                host.preferredContentSize = previewSize
                return host
            }, actionProvider: { [weak self] _ in self?.buildMenu() })
        }

        private func buildMenu() -> UIMenu {
            var children: [UIMenuElement] = []

            // Hàng emoji NGANG — preferredElementSize = .small là API chính khiến
            // submenu này render thành 1 hàng icon compact (thay vì list dọc), tự
            // trượt ngang nếu không đủ chỗ. Đây là public API từ iOS 16.
            let reactionActions = MessageReaction.allCases.map { reaction in
                UIAction(title: reaction.rawValue) { [weak self] _ in self?.onReact(reaction.rawValue) }
            }
            let reactionMenu = UIMenu(
                title: "",
                image: nil,
                identifier: nil,
                options: .displayInline,
                preferredElementSize: .small,
                children: reactionActions
            )
            children.append(reactionMenu)

            children.append(UIAction(title: L10n.Chat.reply, image: UIImage(systemName: "arrowshape.turn.up.left")) { [weak self] _ in
                self?.onReply()
            })
            children.append(UIAction(title: L10n.Chat.copyText, image: UIImage(systemName: "doc.on.doc")) { [weak self] _ in
                self?.onCopy()
            })

            if isOutgoing {
                if message.isEditWindowOpen {
                    children.append(UIAction(title: L10n.Chat.edit, image: UIImage(systemName: "pencil")) { [weak self] _ in
                        self?.onEdit()
                    })
                }
                if message.isRecallWindowOpen {
                    children.append(UIAction(
                        title: L10n.Chat.recall,
                        image: UIImage(systemName: "arrow.uturn.backward"),
                        attributes: .destructive
                    ) { [weak self] _ in
                        self?.onRecall()
                    })
                }
            }

            return UIMenu(children: children)
        }
    }
}
#endif
