//  Pages.swift
//  搜索 / 拍同款 / 朋友 / 消息 / 我 —— 简单页面，主体是首页

import SwiftUI

struct SearchPage: View {
    var onClose: () -> Void
    @State var text = ""
    let hot = ["万能胶", "跟我一起喊", "夏天的风", "晚霞", "三步搞定", "月亮", "白七白", "汽水音乐"]

    var body: some View {
        ZStack {
            Color(white: 0.07).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    HStack(spacing: 6) {
                        SearchIcon(size: 16, color: Color(white: 0.65))
                        TextField("", text: $text)
                            .placeholder(when: text.isEmpty) {
                                Text("搜索你感兴趣的内容").foregroundColor(Color(white: 0.5))
                            }
                            .foregroundColor(.white)
                            .font(pf(15))
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(RoundedRectangle(cornerRadius: 18).fill(Color(white: 0.16)))
                    Button("取消", action: onClose)
                        .foregroundColor(.white)
                        .font(pf(15))
                }
                Text("猜你想搜")
                    .foregroundColor(.white)
                    .font(pf(16, .semibold))
                FlowRow(items: hot)
                Spacer()
            }
            .padding(16)
        }
        .preferredColorScheme(.dark)
    }
}

/// 简单的自动换行标签
struct FlowRow: View {
    let items: [String]

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 74), spacing: 8)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { t in
                Text(t)
                    .font(pf(13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .frame(height: 30)
                    .background(Capsule().fill(Color(white: 0.16)))
            }
        }
    }
}

struct SheetPage: View {
    var title: String
    var subtitle: String? = nil
    var onClose: () -> Void

    var body: some View {
        ZStack {
            Color(white: 0.07).ignoresSafeArea()
            VStack(spacing: 14) {
                Capsule().fill(Color(white: 0.35)).frame(width: 36, height: 4).padding(.top, 10)
                Text(title).font(pf(20, .semibold)).foregroundColor(.white)
                if let s = subtitle {
                    Text(s).font(pf(14)).foregroundColor(Color(white: 0.6))
                }
                Text("这里先留空，需要什么内容告诉我。")
                    .font(pf(14))
                    .foregroundColor(Color(white: 0.45))
                    .padding(.top, 6)
                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }
}

/// 朋友 / 消息 / 我
struct TabPage: View {
    let index: Int
    @Binding var selected: Int
    @ObservedObject var auth = Auth.shared

    let titles = ["首页", "朋友", "", "消息", "我"]

    var body: some View {
        ZStack {
            Color(white: 0.07).ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    content
                        .padding(.bottom, 110)
                }
                Spacer(minLength: 0)
            }
            VStack {
                Spacer()
                BottomBar(selected: $selected, unread: "65", onPlus: { })
                    .frame(height: 90)
            }
        }
    }

    private var header: some View {
        HStack {
            Text(titles[index])
                .font(pf(20, .semibold))
                .foregroundColor(.white)
            Spacer()
            SearchIcon(size: 19, color: Color(white: 0.75))
        }
        .padding(.horizontal, 18)
        .frame(height: 52)
    }

    @ViewBuilder
    private var content: some View {
        switch index {
        case 1:
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)],
                      spacing: 2) {
                ForEach(Store.videos) { v in
                    posterCell(v)
                }
            }
        case 3:
            VStack(spacing: 0) {
                ForEach(Store.videos) { v in
                    HStack(spacing: 12) {
                        AvatarView(name: "avatar-01")
                            .frame(width: 46, height: 46)
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(v.author).font(pf(15, .medium)).foregroundColor(.white)
                            Text(v.caption).font(pf(13)).foregroundColor(Color(white: 0.55)).lineLimit(1)
                        }
                        Spacer()
                        Text("刚刚").font(pf(12)).foregroundColor(Color(white: 0.4))
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 72)
                }
            }
        default:
            VStack(spacing: 16) {
                HStack(spacing: 14) {
                    AvatarView(name: auth.user?.avatar?.isEmpty == false ? (auth.user?.avatar ?? "") : "avatar-01")
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 2))
                    VStack(alignment: .leading, spacing: 6) {
                        Text(auth.user?.name ?? (auth.isLoggedIn ? "@我" : "未登录"))
                            .font(pf(17, .semibold)).foregroundColor(.white)
                        Text(auth.isLoggedIn
                             ? ("抖音号：" + (auth.user?.douyinId ?? "") + " · " + (auth.user?.phone ?? ""))
                             : "登录后可以点赞、评论、关注")
                            .font(pf(12)).foregroundColor(Color(white: 0.5))
                    }
                    Spacer()
                    if auth.isLoggedIn {
                        Button {
                            Task { await auth.logout() }
                        } label: {
                            Text("退出")
                                .font(pf(13))
                                .foregroundColor(Color(white: 0.6))
                                .padding(.horizontal, 12)
                                .frame(height: 32)
                                .background(Capsule().fill(Color(white: 0.14)))
                        }
                    }
                }
                .padding(.horizontal, 18)
                HStack(spacing: 26) {
                    stat("138", "关注")
                    stat("1.2万", "粉丝")
                    stat("8.6万", "获赞")
                    Spacer()
                }
                .padding(.horizontal, 18)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)],
                          spacing: 2) {
                    ForEach(Store.videos) { v in
                        posterCell(v)
                    }
                }
            }
        }
    }

    private func stat(_ n: String, _ t: String) -> some View {
        VStack(spacing: 3) {
            Text(n).font(pf(17, .semibold)).foregroundColor(.white)
            Text(t).font(pf(12)).foregroundColor(Color(white: 0.5))
        }
    }

    private func posterCell(_ v: Video) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let img = Store.image(v.poster) {
                Image(uiImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 240)
                    .clipped()
            } else {
                Color(white: 0.15).frame(height: 240)
            }
            Text(v.caption)
                .font(pf(12))
                .foregroundColor(.white)
                .lineLimit(2)
                .padding(8)
        }
        .frame(height: 240)
        .clipped()
    }
}

extension View {
    /// TextField 的占位文字
    func placeholder<Content: View>(when shouldShow: Bool,
                                    alignment: Alignment = .leading,
                                    @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}
