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
                ForEach(0..<4, id: \.self) { i in
                    let cx = M.bottomItemCenters[i] * scale
                    Button {
                        selected = i < 2 ? i : i + 1
                    } label: {
                        Text(labels[i])
                            .font(font(M.bottomLabelFont, i == 0 ? .semibold : .regular))
                            .foregroundColor(i == 0 ? C.white : C.barIdle)
                            .padding(.horizontal, 8)
                            .frame(height: 34)
                            .contentShape(Rectangle())
                    }
                    .position(x: cx, y: y)
                }

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

                // 我
                Button {
                    selected = 4
                } label: {
                    Text(labels[4])
                        .font(font(M.bottomLabelFont))
                        .foregroundColor(C.barIdle)
                        .padding(.horizontal, 8)
                        .frame(height: 34)
                        .contentShape(Rectangle())
                }
                .position(x: M.bottomItemCenters[3] * scale, y: y)
            }
        }
    }
}
