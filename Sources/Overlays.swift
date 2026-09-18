//  Overlays.swift
//  分享面板 + 长按「更多」菜单（抖音那套）

import SwiftUI

struct ShareSheet: View {
    let video: Video
    var onClose: () -> Void
    @State private var toast = ""

    private let channels: [(String, String, Color)] = [
        ("微信", "message.fill", Color(red: 0.15, green: 0.75, blue: 0.35)),
        ("朋友圈", "camera.circle.fill", Color(red: 0.2, green: 0.65, blue: 0.5)),
        ("QQ", "bubble.left.fill", Color(red: 0.2, green: 0.6, blue: 1)),
        ("微博", "globe.asia.australia.fill", Color(red: 1, green: 0.4, blue: 0.3)),
        ("抖音好友", "person.2.fill", Color(red: 0.6, green: 0.4, blue: 1)),
        ("复制链接", "link", Color(white: 0.35)),
        ("保存本地", "arrow.down.circle.fill", Color(white: 0.35)),
        ("举报", "exclamationmark.triangle.fill", Color(red: 1, green: 0.4, blue: 0.4))
    ]

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8),
                           GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { onClose() }
            VStack(spacing: 14) {
                Capsule().fill(Color(white: 0.3)).frame(width: 36, height: 4)
                Text("分享到").font(pf(14, .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(channels, id: \.0) { c in
                        Button { act(c.0) } label: {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle().fill(c.2).frame(width: 50, height: 50)
                                    Image(systemName: c.1)
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                                Text(c.0).font(pf(11.5)).foregroundColor(Color(white: 0.8))
                            }
                        }
                    }
                }
                Button { onClose() } label: {
                    Text("取消")
                        .font(pf(15, .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 22).fill(Color(white: 0.14)))
                }
            }
            .padding(18)
            .padding(.bottom, 16)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(white: 0.08)))
            .overlay(alignment: .top) {
                if !toast.isEmpty {
                    Text(toast)
                        .font(pf(12.5))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background(Capsule().fill(Color.black.opacity(0.85)))
                        .offset(y: -46)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func act(_ name: String) {
        switch name {
        case "复制链接":
            UIPasteboard.general.string = ServerConfig.base + "/video/" + video.remoteId
            toast = "链接已复制"
        case "保存本地":
            toast = "已保存到相册（演示）"
        case "举报":
            Task {
                struct Res: Codable { var ok: Bool? }
                _ = try? await Api.post("/api/report",
                                        body: ["target": "video", "targetId": video.remoteId, "reason": "用户举报"],
                                        as: Res.self)
            }
            toast = "已收到举报，我们会尽快处理"
        default:
            Task {
                struct Res: Codable { var share: Int?; var shareText: String? }
                _ = try? await Api.post("/api/video/share?id=" + video.remoteId, body: [:], as: Res.self)
            }
            toast = "已分享到" + name
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            onClose()
        }
    }
}

/// 长按「更多」：抖音的倍速/清晰度/不感兴趣/保存/举报都在这
struct MoreMenu: View {
    let video: Video
    var onClose: () -> Void
    @ObservedObject var model: FeedModel
    @State private var rate = "1.0x"
    @State private var quality = "高清"
    @State private var toast = ""

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.opacity(0.45).ignoresSafeArea()
                .onTapGesture { onClose() }
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text("倍速").font(pf(13.5)).foregroundColor(Color(white: 0.6)).frame(width: 52, alignment: .leading)
                    ForEach(["0.5x", "1.0x", "1.5x", "2.0x"], id: \.self) { r in
                        Button { rate = r } label: {
                            Text(r)
                                .font(pf(13, rate == r ? .semibold : .regular))
                                .foregroundColor(rate == r ? .white : Color(white: 0.6))
                                .padding(.horizontal, 12)
                                .frame(height: 30)
                                .background(Capsule().fill(rate == r ? Theme.primary : Color(white: 0.14)))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                Divider().background(Color(white: 0.14))

                HStack(spacing: 12) {
                    Text("清晰度").font(pf(13.5)).foregroundColor(Color(white: 0.6)).frame(width: 52, alignment: .leading)
                    ForEach(["流畅", "高清", "超清"], id: \.self) { q in
                        Button { quality = q } label: {
                            Text(q)
                                .font(pf(13, quality == q ? .semibold : .regular))
                                .foregroundColor(quality == q ? .white : Color(white: 0.6))
                                .padding(.horizontal, 12)
                                .frame(height: 30)
                                .background(Capsule().fill(quality == q ? Theme.primary : Color(white: 0.14)))
                        }
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                Divider().background(Color(white: 0.14))

                menuRow("hand.thumbsdown", "不感兴趣") {
                    model.dislike(video, author: false)
                    onClose()
                }
                menuRow("person.crop.circle.badge.xmark", "不感兴趣 · " + video.author) {
                    model.dislike(video, author: true)
                    onClose()
                }
                menuRow("arrow.down.circle", "保存本地") {
                    toast = "已保存（演示）"
                }
                menuRow("exclamationmark.triangle", "举报") {
                    Task {
                        struct Res: Codable { var ok: Bool? }
                        _ = try? await Api.post("/api/report",
                                                body: ["target": "video", "targetId": video.remoteId, "reason": "长按举报"],
                                                as: Res.self)
                    }
                    toast = "已收到举报"
                }
                Button { onClose() } label: {
                    Text("取消")
                        .font(pf(15, .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color(white: 0.12))
                }
            }
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.07)))
            .overlay(alignment: .top) {
                if !toast.isEmpty {
                    Text(toast)
                        .font(pf(12.5)).foregroundColor(.white)
                        .padding(.horizontal, 14).frame(height: 32)
                        .background(Capsule().fill(Color.black.opacity(0.85)))
                        .offset(y: -46)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func menuRow(_ icon: String, _ title: String, _ tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color(white: 0.8))
                    .frame(width: 22)
                Text(title).font(pf(14.5)).foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 18)
            .frame(height: 50)
            .contentShape(Rectangle())
        }
    }
}
