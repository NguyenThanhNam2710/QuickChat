//
//  MessageActionOverlay.swift
//  QuickChat
//
//  Created by NamNT97 on 29/7/26.
//  Overlay kiểu Telegram — long-press vào 1 bubble sẽ hiện:
//  backdrop mờ + bubble ĐỨNG YÊN đúng vị trí thật + reaction bar nổi NGAY TRÊN bubble +
//  menu hành động nổi NGAY DƯỚI bubble. Reaction/menu tự kẹp (clamp) trong vùng an toàn,
//  sẵn sàng đè lên bubble nếu bubble quá cao/quá sát mép màn hình — không còn cần tính
//  tổng chiều cao cluster hay ScrollView như bản trước.
//
//  Bug đã sửa lần này:
//  - Bug 1 (reaction bar lọt vào vùng nav bar, không bấm được): nguyên nhân là
//    `.ignoresSafeArea()` đặt trên GeometryReader khiến nó phồng ra phủ cả nav bar,
//    trong khi `safeAreaInsets.top` KHÔNG hề biết chiều cao nav bar (chỉ biết status bar/notch
//    của thiết bị) — dẫn tới safeTop bị tính thiếu. Bỏ hẳn `.ignoresSafeArea()` ở đây: overlay
//    này được gắn qua `.overlayPreferenceValue` lên VStack nội dung của ChatView, vốn đã nằm
//    DƯỚI nav bar sẵn — nên toạ độ (0,0) của GeometryReader tự nhiên bắt đầu ngay dưới nav bar,
//    không cần bù trừ gì thêm.
//  - Bug 2 (tin dài mất hẳn reaction bar): bỏ cách cũ "gộp cluster rồi tính tổng chiều cao,
//    quá cao thì bọc ScrollView". Giờ bubble giữ nguyên vị trí/kích thước thật, reaction bar
//    và menu mỗi cái tự kẹp vị trí riêng trong vùng an toàn — nếu bubble quá cao, chúng đè
//    lên phần bubble thay vì biến mất.
//

import SwiftUI

struct MessageActionOverlay: View {
    let context: MessageActionContext
    let currentUserID: String
    let onReply: () -> Void
    let onCopy: () -> Void
    let onEdit: () -> Void
    let onRecall: () -> Void
    let onReact: (String) -> Void
    let onDismiss: () -> Void

    private var message: Message { context.item.message }
    private var isOutgoing: Bool { context.isOutgoing }

    private let reactionBarHeight: CGFloat = 44
    /// Ước lượng bề rộng thanh 6 emoji — chỉ dùng để KẸP vị trí ngang, không ảnh hưởng
    /// kích thước hiển thị thật (Capsule tự co theo nội dung, `.fixedSize` ngầm định).
    private let reactionBarEstimatedWidth: CGFloat = 220
    private let menuRowHeight: CGFloat = 44
    private let menuWidth: CGFloat = 240
    private let stackSpacing: CGFloat = Spacing.sm
    private let horizontalMargin: CGFloat = Spacing.md

    private var menuRowCount: Int {
        guard !message.isRecalled else { return 0 }
        var count = 2 // Reply + Copy luôn có
        if isOutgoing && message.isEditWindowOpen { count += 1 }
        if isOutgoing && message.isRecallWindowOpen { count += 1 }
        return count
    }

    private var menuHeight: CGFloat { CGFloat(menuRowCount) * menuRowHeight }

    var body: some View {
        GeometryReader { screen in
            let safeTop = screen.safeAreaInsets.top + Spacing.sm
            let safeBottom = screen.size.height - screen.safeAreaInsets.bottom - Spacing.sm

            ZStack {
                Color.black.opacity(0.35)
                    .onTapGesture { onDismiss() }

                // Bubble giữ NGUYÊN vị trí + kích thước thật trên màn hình — không di chuyển,
                // không co giãn. Đúng tinh thần Telegram: tin nhắn "đứng yên", các thành phần
                // khác tự nổi quanh nó.
                MessageBubbleContentView(message: message, isOutgoing: isOutgoing, currentUserID: currentUserID)
                    .frame(width: context.frame.width, height: context.frame.height)
                    .position(x: context.frame.midX, y: context.frame.midY)

                if !message.isRecalled {
                    reactionBar
                        .position(
                            x: clampedCenterX(
                                preferred: context.frame.midX,
                                width: reactionBarEstimatedWidth,
                                screenWidth: screen.size.width
                            ),
                            // Ưu tiên đặt NGAY TRÊN mép bubble; nếu vị trí đó lọt lên trên nav bar
                            // (bubble ở gần đỉnh màn hình), ép xuống mép an toàn — lúc này reaction
                            // bar sẽ đè lên phần trên của bubble thay vì bị khuất/không bấm được.
                            y: max(
                                context.frame.minY - stackSpacing - reactionBarHeight / 2,
                                safeTop + reactionBarHeight / 2
                            )
                        )

                    actionMenu
                        .frame(width: menuWidth)
                        .position(
                            x: clampedCenterX(
                                preferred: context.frame.midX,
                                width: menuWidth,
                                screenWidth: screen.size.width
                            ),
                            // Ưu tiên đặt NGAY DƯỚI mép bubble; nếu bubble quá cao khiến vị trí đó
                            // vượt quá đáy vùng an toàn, ép lên — menu sẽ đè lên phần dưới của bubble
                            // thay vì bị đẩy mất khỏi màn hình (Bug 2, tin nhắn rất dài).
                            y: min(
                                context.frame.maxY + stackSpacing + menuHeight / 2,
                                safeBottom - menuHeight / 2
                            )
                        )
                }
            }
        }
    }

    private func clampedCenterX(preferred: CGFloat, width: CGFloat, screenWidth: CGFloat) -> CGFloat {
        let half = width / 2
        let minX = horizontalMargin + half
        let maxX = screenWidth - horizontalMargin - half
        guard maxX >= minX else { return screenWidth / 2 }
        return min(max(preferred, minX), maxX)
    }

    private var reactionBar: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(MessageReaction.allCases, id: \.rawValue) { reaction in
                Button {
                    onReact(reaction.rawValue)
                } label: {
                    Text(reaction.rawValue).font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(.regularMaterial, in: Capsule())
    }

    private var actionMenu: some View {
        VStack(spacing: 0) {
            menuRow(title: L10n.Chat.reply, systemImage: "arrowshape.turn.up.left", action: onReply)
            Divider()
            menuRow(title: L10n.Chat.copyText, systemImage: "doc.on.doc", action: onCopy)
            if isOutgoing && message.isEditWindowOpen {
                Divider()
                menuRow(title: L10n.Chat.edit, systemImage: "pencil", action: onEdit)
            }
            if isOutgoing && message.isRecallWindowOpen {
                Divider()
                menuRow(title: L10n.Chat.recall, systemImage: "arrow.uturn.backward", isDestructive: true, action: onRecall)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func menuRow(title: String, systemImage: String, isDestructive: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Image(systemName: systemImage)
            }
            .foregroundStyle(isDestructive ? .red : .primary)
            .padding(.horizontal, Spacing.md)
            .frame(height: menuRowHeight)
        }
        .buttonStyle(.plain)
    }
}
