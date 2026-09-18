//  Icons.swift
//  手绘图标（不用 SF Symbols，避免形状跟参考图差太远）

import SwiftUI

/// 顶栏左上角的“三横”菜单图标：三条左对齐、宽度递减的白条
struct MenuIcon: View {
    var width: CGFloat = 20
    var color: Color = .white

    var body: some View {
        VStack(alignment: .leading, spacing: M.menuBarSpacing) {
            ForEach(0..<3, id: \.self) { i in
                Capsule()
                    .fill(color)
                    .frame(width: width * [1.0, 0.8, 0.6][i], height: M.menuBarHeight)
            }
        }
        .frame(width: width, alignment: .leading)
    }
}

/// 放大镜
struct SearchIcon: View {
    var size: CGFloat = 21
    var color: Color = .white

    var body: some View {
        let stroke = size * 0.105
        return ZStack {
            Circle()
                .stroke(color, lineWidth: stroke)
                .frame(width: size * 0.74, height: size * 0.74)
                .position(x: size * 0.38, y: size * 0.38)
            Capsule()
                .fill(color)
                .frame(width: stroke * 1.35, height: size * 0.40)
                .rotationEffect(.degrees(-45))
                .position(x: size * 0.80, y: size * 0.80)
        }
        .frame(width: size, height: size)
    }
}

/// 实心爱心
struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: 0.50 * w, y: 0.96 * h))
        p.addCurve(to: CGPoint(x: 0.02 * w, y: 0.34 * h),
                   control1: CGPoint(x: 0.36 * w, y: 0.80 * h),
                   control2: CGPoint(x: 0.02 * w, y: 0.58 * h))
        p.addCurve(to: CGPoint(x: 0.28 * w, y: 0.02 * h),
                   control1: CGPoint(x: 0.02 * w, y: 0.14 * h),
                   control2: CGPoint(x: 0.12 * w, y: 0.02 * h))
        p.addCurve(to: CGPoint(x: 0.50 * w, y: 0.16 * h),
                   control1: CGPoint(x: 0.39 * w, y: 0.02 * h),
                   control2: CGPoint(x: 0.46 * w, y: 0.08 * h))
        p.addCurve(to: CGPoint(x: 0.72 * w, y: 0.02 * h),
                   control1: CGPoint(x: 0.54 * w, y: 0.08 * h),
                   control2: CGPoint(x: 0.61 * w, y: 0.02 * h))
        p.addCurve(to: CGPoint(x: 0.98 * w, y: 0.34 * h),
                   control1: CGPoint(x: 0.88 * w, y: 0.02 * h),
                   control2: CGPoint(x: 0.98 * w, y: 0.14 * h))
        p.addCurve(to: CGPoint(x: 0.50 * w, y: 0.96 * h),
                   control1: CGPoint(x: 0.98 * w, y: 0.58 * h),
                   control2: CGPoint(x: 0.64 * w, y: 0.80 * h))
        p.closeSubpath()
        return p
    }
}

/// 评论气泡（圆角方 + 左下小尾巴）
struct CommentIcon: View {
    var size: CGFloat = 32
    var color: Color = .white

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.30, style: .continuous)
                .fill(color)
                .frame(width: size * 0.96, height: size * 0.76)
                .position(x: size * 0.50, y: size * 0.38)
            Path { p in
                p.move(to: CGPoint(x: size * 0.22, y: size * 0.60))
                p.addLine(to: CGPoint(x: size * 0.20, y: size * 0.98))
                p.addLine(to: CGPoint(x: size * 0.52, y: size * 0.74))
                p.closeSubpath()
            }
            .fill(color)
        }
        .frame(width: size, height: size)
    }
}

/// 五角星（收藏）
struct StarShape: Shape {
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let outer = min(rect.width, rect.height) / 2
        let inner = outer * 0.44
        var p = Path()
        for i in 0..<10 {
            let r = i % 2 == 0 ? outer : inner
            let a = (Double(i) * 36.0 - 90.0) * Double.pi / 180.0
            let pt = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

/// 分享（纸飞机箭头）
struct ShareShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width
        let h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: 0.02 * w, y: 0.42 * h))
        p.addLine(to: CGPoint(x: 0.99 * w, y: 0.02 * h))
        p.addLine(to: CGPoint(x: 0.60 * w, y: 0.99 * h))
        p.addLine(to: CGPoint(x: 0.45 * w, y: 0.58 * h))
        p.closeSubpath()
        return p
    }
}

/// 音符
struct MusicNoteIcon: View {
    var size: CGFloat = 13
    var color: Color = .white

    var body: some View {
        ZStack {
            Ellipse()
                .fill(color)
                .frame(width: size * 0.44, height: size * 0.36)
                .position(x: size * 0.30, y: size * 0.82)
            Rectangle()
                .fill(color)
                .frame(width: size * 0.13, height: size * 0.72)
                .position(x: size * 0.46, y: size * 0.42)
            Rectangle()
                .fill(color)
                .frame(width: size * 0.42, height: size * 0.15)
                .position(x: size * 0.68, y: size * 0.08)
        }
        .frame(width: size, height: size)
    }
}

/// 加号
struct PlusIcon: View {
    var size: CGFloat = 7
    var thickness: CGFloat = 2.4
    var color: Color = .white

    var body: some View {
        ZStack {
            Capsule().fill(color).frame(width: size, height: thickness)
            Capsule().fill(color).frame(width: thickness, height: size)
        }
        .frame(width: size, height: size)
    }
}

/// 小箭头
enum ChevronDirection { case right, down, up }

struct ChevronIcon: View {
    var size: CGFloat = 9
    var thickness: CGFloat = 1.8
    var direction: ChevronDirection = .right
    var color: Color = .white

    var body: some View {
        Group {
            switch direction {
            case .down, .up:
                Path { p in
                    p.move(to: CGPoint(x: 0, y: size * (direction == .up ? 1.0 : 0.0)))
                    p.addLine(to: CGPoint(x: size * 0.5, y: size * (direction == .up ? 0.0 : 1.0)))
                    p.addLine(to: CGPoint(x: size, y: size * (direction == .up ? 1.0 : 0.0)))
                }
                .stroke(color, style: StrokeStyle(lineWidth: thickness, lineCap: .round, lineJoin: .round))
                .frame(width: size, height: size)
            case .right:
                Path { p in
                    p.move(to: CGPoint(x: size * 0.25, y: 0))
                    p.addLine(to: CGPoint(x: size * 0.9, y: size * 0.5))
                    p.addLine(to: CGPoint(x: size * 0.25, y: size))
                }
                .stroke(color, style: StrokeStyle(lineWidth: thickness, lineCap: .round, lineJoin: .round))
                .frame(width: size, height: size)
            }
        }
    }
}
