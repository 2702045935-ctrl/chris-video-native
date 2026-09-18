//  TopBar.swift
//  顶部：三横菜单 + 可横向滚动的一排 tab + 搜索

import SwiftUI

struct TopBar: View {
    let tabs: [String]
    @Binding var selected: Int
    var onSearch: () -> Void
    var onMenu: () -> Void

    var body: some View {
        GeometryReader { geo in
            // 这个视图本身处在“安全区之内”的坐标空间里，y=0 就是状态栏下面
            let centerY = M.topBarCenterBelowSafeTop
            let stripWidth = M.tabItemWidth * CGFloat(tabs.count)
            let stripLeading = M.tabStripLeading
            let available = geo.size.width - stripLeading - M.searchCenterTrailing - M.searchSize / 2 - 12

            ZStack(alignment: .topLeading) {
                // 左上：三横菜单
                Button(action: onMenu) {
                    MenuIcon(width: M.menuBarWidths[0])
                        .frame(width: M.menuBarWidths[0], height: 26, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .frame(height: M.topBarHeight)
                .position(x: M.menuLeading + M.menuBarWidths[0] / 2, y: centerY)

                // 中间：tab 条（内容比可视区宽时可以横向滑）
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(0..<tabs.count, id: \.self) { i in
                            Button {
                                selected = i
                            } label: {
                                Text(tabs[i])
                                    .font(font(i == selected ? M.tabFontActive : M.tabFontIdle,
                                               i == selected ? .bold : .regular))
                                    .foregroundColor(i == selected ? C.white : C.tabIdle)
                                    .frame(width: M.tabItemWidth, height: M.topBarHeight)
                                    .contentShape(Rectangle())
                            }
                        }
                    }
                    .frame(width: stripWidth, height: M.topBarHeight, alignment: .leading)
                }
                .frame(width: max(120, min(stripWidth, available)), height: M.topBarHeight, alignment: .leading)
                .position(x: stripLeading + max(120, min(stripWidth, available)) / 2, y: centerY)

                // 右上：搜索
                Button(action: onSearch) {
                    SearchIcon(size: M.searchSize)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .position(x: geo.size.width - M.searchCenterTrailing, y: centerY)
            }
        }
    }
}
