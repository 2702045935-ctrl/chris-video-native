//  RailView.swift
//  右侧操作栏：头像(+关注)、赞、评论、收藏、分享、拍同款

import SwiftUI

struct RailView: View {
    let video: Video
    var onLike: () -> Void
    var onStar: () -> Void
    var onComment: () -> Void
    var onShare: () -> Void
    var onFollow: () -> Void
    var onSameStyle: () -> Void

    var body: some View {
        GeometryReader { geo in
            let cx = geo.size.width - M.railCenterTrailing
            let b = geo.size.height
            let iconScale = Theme.railIconScale

            ZStack(alignment: .topLeading) {
                AvatarView(name: video.avatar)
                    .frame(width: M.avatarSize, height: M.avatarSize)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white, lineWidth: M.avatarRing))
                    .position(x: cx, y: b - M.railAvatarAboveBottom)

                if Theme.showFollow && !video.following {
                    Button(action: onFollow) {
                        ZStack {
                            Circle().fill(Theme.primary)
                            PlusIcon(size: 9, thickness: 2.1, color: .white)
                        }
                        .frame(width: M.followBadge, height: M.followBadge)
                        .contentShape(Rectangle())
                    }
                    .position(x: cx, y: b - M.railBadgeAboveBottom)
                }

                Button(action: onLike) {
                    HeartShape()
                        .fill(video.liked ? Theme.primary : Color.white)
                        .frame(width: M.likeIconSize * iconScale, height: M.likeIconSize * iconScale * 0.92)
                }
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
                .position(x: cx, y: b - M.railLikeAboveBottom)

                countText(video.likes)
                    .position(x: cx, y: b - M.railLikeAboveBottom + M.railCountBelowIcon)

                Button(action: onComment) {
                    CommentIcon(size: M.commentIconSize * iconScale)
                }
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
                .position(x: cx, y: b - M.railCommentAboveBottom)

                countText(video.comments)
                    .position(x: cx, y: b - M.railCommentAboveBottom + M.railCountBelowIcon)

                Button(action: onStar) {
                    StarShape()
                        .fill(video.favorited ? Theme.star : Color.white)
                        .frame(width: M.starIconSize * iconScale, height: M.starIconSize * iconScale)
                }
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
                .position(x: cx, y: b - M.railStarAboveBottom)

                countText(video.favorites)
                    .position(x: cx, y: b - M.railStarAboveBottom + M.railCountBelowIcon)

                Button(action: onShare) {
                    ShareShape()
                        .fill(Color.white)
                        .frame(width: M.shareIconSize * iconScale, height: M.shareIconSize * iconScale * 0.78)
                }
                .frame(width: 52, height: 52)
                .contentShape(Rectangle())
                .position(x: cx, y: b - M.railShareAboveBottom)

                countText(video.shares)
                    .position(x: cx, y: b - M.railShareAboveBottom + M.railCountBelowIcon)

                MusicNoteIcon(size: M.musicNoteSize)
                    .position(x: cx, y: b - M.railNoteAboveBottom)

                Button(action: onSameStyle) {
                    Text("拍同款")
                        .font(pf(Theme.sameStyleFont, .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 2)
                        .padding(.vertical, 4)
                        .contentShape(Rectangle())
                }
                .position(x: cx, y: b - M.railSameStyleAboveBottom)
            }
        }
    }

    private func countText(_ s: String) -> some View {
        Text(s)
            .font(pf(Theme.countFont, .semibold))
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.25), radius: 1, x: 0, y: 0.5)
    }
}

/// 头像：支持后台地址（http）和 App 内置图片，都没有就画剪影
struct AvatarView: View {
    let name: String

    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            if name.hasPrefix("http") {
                AsyncImage(url: URL(string: name)) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().aspectRatio(contentMode: .fill)
                    default:
                        placeholder(s)
                    }
                }
                .frame(width: s, height: s)
                .clipped()
            } else if let img = Store.image(name) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: s, height: s)
                    .clipped()
            } else {
                placeholder(s)
            }
        }
    }

    private func placeholder(_ s: CGFloat) -> some View {
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
