//  RailView.swift
//  右侧操作栏：头像+关注、赞、评论、收藏、分享、拍同款

import SwiftUI

struct RailView: View {
    let video: Video
    @Binding var liked: Bool
    @Binding var starred: Bool
    var onComment: () -> Void
    var onShare: () -> Void
    var onSameStyle: () -> Void

    private func likeText(_ s: String) -> String {
        liked ? bump(s) : s
    }

    private func bump(_ s: String) -> String {
        if s.hasSuffix("万") { return s }
        if let n = Int(s) { return "\(n + 1)" }
        return s
    }

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width - M.railCenterTrailing
            let b = geo.size.height

            ZStack(alignment: .topLeading) {
                // 头像
                AvatarView(name: avatarName)
                    .frame(width: M.avatarSize, height: M.avatarSize)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: M.avatarRing))
                    .position(x: cx, y: b - M.railAvatarAboveBottom)

                // 关注 ＋
                ZStack {
                    Circle().fill(C.red)
                    PlusIcon(size: 9, thickness: 2.1, color: .white)
                }
                .frame(width: M.followBadge, height: M.followBadge)
                .position(x: cx, y: b - M.railBadgeAboveBottom)

                // 赞
                Button { liked.toggle() } label: {
                    HeartShape()
                        .fill(liked ? C.red : Color.white)
                        .frame(width: M.likeIconSize * 0.95, height: M.likeIconSize * 0.9)
                }
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
                .position(x: cx, y: b - M.railLikeAboveBottom)

                countText(likeText(video.likes))
                    .position(x: cx, y: b - M.railLikeAboveBottom + M.railCountBelowIcon)

                // 评论
                Button(action: onComment) {
                    CommentIcon(size: M.commentIconSize)
                }
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
                .position(x: cx, y: b - M.railCommentAboveBottom)

                countText(video.comments)
                    .position(x: cx, y: b - M.railCommentAboveBottom + M.railCountBelowIcon)

                // 收藏
                Button { starred.toggle() } label: {
                    StarShape()
                        .fill(starred ? Color(red: 1, green: 0.78, blue: 0.16) : Color.white)
                        .frame(width: M.starIconSize, height: M.starIconSize)
                }
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
                .position(x: cx, y: b - M.railStarAboveBottom)

                countText(video.favorites)
                    .position(x: cx, y: b - M.railStarAboveBottom + M.railCountBelowIcon)

                // 分享
                Button(action: onShare) {
                    ShareShape()
                        .fill(Color.white)
                        .frame(width: M.shareIconSize, height: M.shareIconSize * 0.78)
                }
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
                .position(x: cx, y: b - M.railShareAboveBottom)

                countText(video.shares)
                    .position(x: cx, y: b - M.railShareAboveBottom + M.railCountBelowIcon)

                // 拍同款
                MusicNoteIcon(size: M.musicNoteSize)
                    .position(x: cx, y: b - M.railNoteAboveBottom)

                Button(action: onSameStyle) {
                    Text("拍同款")
                        .font(font(M.sameStyleFont, .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                }
                .position(x: cx, y: b - M.railSameStyleAboveBottom)
            }
        }
    }

    private var avatarName: String {
        "avatar-01"
    }

    private func countText(_ s: String) -> some View {
        Text(s)
            .font(font(M.railCountFont, .semibold))
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.25), radius: 1, x: 0, y: 0.5)
    }
}

/// 头像：优先用打包的图片，没有就画一个剪影
struct AvatarView: View {
    let name: String

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            if let img = Store.image(name) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: s, height: s)
                    .clipped()
            } else {
                ZStack {
                    LinearGradient(colors: [Color(white: 0.35), Color(white: 0.18)],
                                   startPoint: .top, endPoint: .bottom)
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: s * 0.34, height: s * 0.34)
                        .position(x: s / 2, y: s * 0.34)
                    Capsule()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: s * 0.62, height: s * 0.40)
                        .position(x: s / 2, y: s * 0.92)
                }
                .frame(width: s, height: s)
            }
        }
    }
}
