//  FriendsPage.swift
//  朋友页：顶部 朋友/关注 两个 tab + 双列作品流（抖音的朋友页是双列瀑布流）

import SwiftUI

struct FriendsPage: View {
    var onOpenSearch: () -> Void
    @State private var tab = 0
    @State private var items: [Video] = []
    @State private var loading = true

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 18) {
                Button { tab = 0 } label: {
                    Text("朋友")
                        .font(pf(17, tab == 0 ? .semibold : .regular))
                        .foregroundColor(tab == 0 ? .white : Color(white: 0.6))
                }
                Button { tab = 1 } label: {
                    Text("关注")
                        .font(pf(17, tab == 1 ? .semibold : .regular))
                        .foregroundColor(tab == 1 ? .white : Color(white: 0.6))
                }
                Spacer()
                Button(action: onOpenSearch) {
                    SearchIcon(size: 19, color: Color(white: 0.75))
                        .frame(width: 40, height: 40)
                }
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Color.black)

            if loading {
                Spacer()
                ProgressView().tint(.white)
                Spacer()
            } else if items.isEmpty {
                Spacer()
                VStack(spacing: 10) {
                    Text(tab == 0 ? "还没有朋友的作品" : "还没有关注的人")
                        .font(pf(15, .semibold))
                        .foregroundColor(.white)
                    Text(tab == 0 ? "互相关注后，这里会显示 TA 的作品" : "去首页关注几个作者试试")
                        .font(pf(13))
                        .foregroundColor(Color(white: 0.5))
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)],
                              spacing: 2) {
                        ForEach(items) { v in
                            PosterCell(video: v)
                        }
                    }
                    .padding(.bottom, 90)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .task { await load() }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        let path = tab == 0 ? "/api/feed?tab=recommend&cursor=0&count=20" : "/api/feed?tab=follow&cursor=0&count=20"
        struct Feed: Codable { var items: [RemoteVideo]? }
        if let r = try? await Api.get(path, as: Feed.self), let list = r.items {
            items = list.enumerated().map { Store.fromRemote($0.element, index: $0.offset) }
        } else {
            items = []
        }
    }
}

/// 双列流里的一格：封面 + 播放量 + 文案
struct PosterCell: View {
    let video: Video

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            poster
                .frame(height: 260)
                .clipped()
            LinearGradient(colors: [Color.clear, Color.black.opacity(0.55)],
                           startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 3) {
                Text(video.caption)
                    .font(pf(12.5))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill").font(.system(size: 10))
                    Text(video.likes).font(pf(11))
                    Image(systemName: "play.fill").font(.system(size: 10)).padding(.leading, 4)
                    Text(video.shares).font(pf(11))
                }
                .foregroundColor(Color(white: 0.85))
            }
            .padding(8)
        }
        .frame(height: 260)
        .clipped()
    }

    @ViewBuilder
    private var poster: some View {
        if video.poster.hasPrefix("http") {
            AsyncImage(url: URL(string: video.poster)) { phase in
                if case .success(let img) = phase {
                    img.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color(white: 0.12)
                }
            }
        } else if let img = Store.image(video.poster) {
            Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
        } else {
            Color(white: 0.12)
        }
    }
}
