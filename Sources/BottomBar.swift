//  BottomBar.swift
//  底栏：首页 / 朋友 / ＋ / 消息(红色 65 徽标) / 我

import SwiftUI

struct BottomBar: View {
    @Binding var selected: Int
    var unread: String
    var onPlus: () -> Void

    let labels = ["首页", "朋友", "", "消息", "我"]

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let scale = w / M.refW
            let b = geo.size.height
            let y = b - M.bottomBarFromBottom

            ZStack(alignment: .topLeading) {
                barLabel(0, scale: scale, y: y)
                barLabel(1, scale: scale, y: y)
                barLabel(2, scale: scale, y: y)
                barLabel(3, scale: scale, y: y)

                // 首页后面那个小标记
                ChevronIcon(size: 7, thickness: 1.7, direction: .down, color: C.barIdle)
                    .position(x: M.homeMarkCenterX * scale, y: y - 2)

                // 中间 ＋
                Button(action: onPlus) {
                    ZStack {
                        RoundedRectangle(cornerRadius: M.plusRadius, style: .continuous)
                            .fill(C.plusFill)
                        RoundedRectangle(cornerRadius: M.plusRadius, style: .continuous)
                            .stroke(Color.white, lineWidth: M.plusStroke)
                        PlusIcon(size: M.plusArmWidth, thickness: 2.3, color: .white)
                    }
                    .frame(width: M.plusWidth, height: M.plusHeight)
                    .contentShape(Rectangle())
                }
                .position(x: M.plusCenterX * scale, y: y)

                // 消息：红色未读徽标
                Button {
                    selected = 3
                } label: {
                    Text(unread)
                        .font(font(M.badgeFont, .semibold))
                        .foregroundColor(.white)
                        .frame(width: M.badgeWidth, height: M.badgeHeight)
                        .background(Capsule().fill(C.red))
                        .contentShape(Rectangle())
                }
                .position(x: M.badgeCenterX * scale, y: b - M.badgeAboveBottom)

            }
        }
    }

    /// 0/1 → 首页、朋友；2 → 消息；3 → 我
    private func barLabel(_ i: Int, scale: CGFloat, y: CGFloat) -> some View {
        let text = labels[i == 0 ? 0 : (i == 1 ? 1 : (i == 2 ? 3 : 4))]
        let target = i < 2 ? i : i + 1
        let active = i == 0
        return Button {
            selected = target
        } label: {
            Text(text)
                .font(font(M.bottomLabelFont, active ? .semibold : .regular))
                .foregroundColor(active ? C.white : C.barIdle)
                .padding(.horizontal, 8)
                .frame(height: 34)
                .contentShape(Rectangle())
        }
        .position(x: M.bottomItemCenters[i] * scale, y: y)
    }
}
