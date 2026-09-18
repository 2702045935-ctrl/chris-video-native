//  CaptionView.swift
//  左下：共X人推荐 / @作者 / 文案 / 音乐

import SwiftUI

struct CaptionView: View {
    let video: Video
    var onRecommend: () -> Void
    var onMusic: () -> Void

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let b = geo.size.height

            ZStack(alignment: .topLeading) {
                // 「共 251 人推荐 ›」底衬胶囊
                Button(action: onRecommend) {
                    HStack(spacing: 4) {
                        Text(video.recommend)
                            .font(pf(Theme.pillFont, .medium))
                            .foregroundColor(.white)
                        ChevronIcon(size: 7, thickness: 1.6, direction: .right,
                                    color: Color.white.opacity(0.85))
                    }
                    .padding(.horizontal, 8)
                    .frame(height: M.pillHeight)
                    .background(Capsule().fill(C.pill))
                    .contentShape(Rectangle())
                }
                .fixedSize()
                .padding(.leading, M.pillLeading)
                .frame(width: w, alignment: .leading)
                .position(x: w / 2, y: b - M.pillFromBottom)
                .opacity(Theme.showRecommend && !video.recommend.isEmpty ? 1 : 0)

                // 作者
                Text(video.author)
                    .font(pf(Theme.authorFont, .semibold))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.22), radius: 2, x: 0, y: 1)
                    .fixedSize()
                    .padding(.leading, M.captionLeading)
                    .frame(width: w, alignment: .leading)
                    .position(x: w / 2, y: b - M.authorFromBottom)

                // 文案
                Text(video.caption)
                    .font(pf(Theme.captionFont))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(width: M.captionMaxWidth, alignment: .leading)
                    .shadow(color: Color.black.opacity(0.22), radius: 2, x: 0, y: 1)
                    .padding(.leading, M.captionLeading)
                    .frame(width: w, alignment: .leading)
                    .position(x: w / 2, y: b - M.captionFromBottom)

                // 音乐
                Button(action: onMusic) {
                    HStack(spacing: 5) {
                        MusicNoteIcon(size: 12)
                        Text(video.musicLine)
                            .font(pf(Theme.musicFont))
                            .foregroundColor(.white)
                        ChevronIcon(size: 7, thickness: 1.6, direction: .right,
                                    color: Color.white.opacity(0.9))
                        Text("《" + video.musicTitle + "》")
                            .font(pf(Theme.musicFont))
                            .foregroundColor(.white)
                    }
                    .contentShape(Rectangle())
                }
                .fixedSize()
                .padding(.leading, M.captionLeading)
                .frame(width: w, alignment: .leading)
                .position(x: w / 2, y: b - M.musicLineFromBottom)
                .opacity(Theme.showMusic ? 1 : 0)
            }
        }
    }
}
