//  Core.swift
//  设计 token —— 全部来自参考图的像素测量（参考图 1260x2736px @3x = 420x912pt）

import SwiftUI

// MARK: - 颜色

enum C {
    static let white = Color.white
    /// 顶栏未选中的 tab：白 76%
    static let tabIdle = Color.white.opacity(0.76)
    /// 底栏未选中的文字：白 55%
    static let barIdle = Color.white.opacity(0.55)
    /// 抖音红（参考图徽标取色 #FE2C55）
    static let red = Color(red: 0xFE / 255.0, green: 0x2C / 255.0, blue: 0x55 / 255.0)
    /// “共 X 人推荐” 的底衬：白 8.6%
    static let pill = Color.white.opacity(0.086)
    /// 中间 ＋ 按钮的填充：白 33%
    static let plusFill = Color.white.opacity(0.33)
    static let videoBG = Color.black
}

// MARK: - 尺寸（pt，参考图 @3x 除 3）

enum M {
    /// 参考画画布
    static let refW: CGFloat = 420
    static let refH: CGFloat = 912

    // 顶栏
    static let topBarHeight: CGFloat = 44
    /// 顶栏中心离“安全区顶部”的距离（参考图安全区顶 59pt，顶栏中心 90pt）
    static let topBarCenterBelowSafeTop: CGFloat = 31
    static let menuLeading: CGFloat = 18
    static let menuBarWidths: [CGFloat] = [20, 16, 12]
    static let menuBarHeight: CGFloat = 2
    static let menuBarSpacing: CGFloat = 4.3
    static let tabItemWidth: CGFloat = 46
    static let tabStripLeading: CGFloat = 45.6
    static let tabFontIdle: CGFloat = 16.5
    static let tabFontActive: CGFloat = 17.5
    static let searchCenterTrailing: CGFloat = 28.2
    static let searchSize: CGFloat = 21

    // 右侧操作栏（x 中心离屏幕右边 29pt；y 从“安全区底部”往上数，参考机安全区底 = 878pt）
    static let railCenterTrailing: CGFloat = 29
    static let railAvatarAboveBottom: CGFloat = 440.1
    static let railBadgeAboveBottom: CGFloat = 411.5
    static let railLikeAboveBottom: CGFloat = 370.6
    static let railCommentAboveBottom: CGFloat = 300.7
    static let railStarAboveBottom: CGFloat = 230.5
    static let railShareAboveBottom: CGFloat = 159.3
    static let railNoteAboveBottom: CGFloat = 82.4
    static let railSameStyleAboveBottom: CGFloat = 68
    static let avatarSize: CGFloat = 48
    static let avatarRing: CGFloat = 2.3
    static let followBadge: CGFloat = 20
    static let railIconPitch: CGFloat = 70.4
    static let railCountBelowIcon: CGFloat = 29.8
    static let railCountFont: CGFloat = 12.5
    static let railIconFont: CGFloat = 32
    static let likeIconSize: CGFloat = 32
    static let commentIconSize: CGFloat = 32
    static let starIconSize: CGFloat = 30
    static let shareIconSize: CGFloat = 30
    static let musicNoteSize: CGFloat = 13
    static let sameStyleFont: CGFloat = 13

    // 左下文案块（中心 y 离安全区底部的距离）
    static let musicLineFromBottom: CGFloat = 72
    static let captionFromBottom: CGFloat = 105.7
    static let authorFromBottom: CGFloat = 138.3
    static let pillFromBottom: CGFloat = 176.5
    static let captionLeading: CGFloat = 12.7
    static let pillLeading: CGFloat = 12
    static let pillHeight: CGFloat = 28
    static let pillFont: CGFloat = 14.5
    static let authorFont: CGFloat = 17
    static let captionFont: CGFloat = 15
    static let musicFont: CGFloat = 14
    static let captionMaxWidth: CGFloat = 292

    // 底栏（中心 y 离安全区底部的距离）
    static let bottomBarFromBottom: CGFloat = 24.5          // 文字/＋ 中心
    static let badgeAboveBottom: CGFloat = 32.2
    static let homeMarkCenterX: CGFloat = 65.4
    static let badgeCenterX: CGFloat = 317.6
    static let bottomLabelFont: CGFloat = 16
    static let bottomItemCenters: [CGFloat] = [42, 126, 294, 378]
    static let plusCenterX: CGFloat = 210.3
    static let plusWidth: CGFloat = 36.7
    static let plusHeight: CGFloat = 29.7
    static let plusRadius: CGFloat = 9
    static let plusStroke: CGFloat = 2.7
    static let plusArmWidth: CGFloat = 7
    static let badgeWidth: CGFloat = 23.3
    static let badgeHeight: CGFloat = 17.7
    static let badgeFont: CGFloat = 13
}

// MARK: - 小工具

extension View {
    /// 按参考图的绝对 x 摆放（相对参考画布 420pt 宽做等比换算不合逻辑的地方，一律用常量内缩）
    func at(x: CGFloat, y: CGFloat) -> some View {
        self.position(x: x, y: y)
    }
}

/// 一行文字的最亮处对齐用不到，这里只做统一的字重/字体封装
func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
    Font.system(size: size, weight: weight)
}
