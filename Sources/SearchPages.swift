//  SearchPages.swift
//  搜索：热搜榜 + 搜索历史 + 猜你想搜 + 结果（视频/用户/话题）

import SwiftUI

struct SearchPage2: View {
    var onClose: () -> Void
    @State private var text = ""
    @State private var submitted = ""
    @State private var hot: [HotItem] = []
    @State private var videos: [Video] = []
    @State private var users: [UserRow] = []
    @State private var topics: [TopicRow] = []
    @State private var history: [String] = []
    @State private var tab = 0
    @FocusState private var focused: Bool

    struct HotItem: Codable, Identifiable {
        var rank: Int
        var word: String
        var hot: Int?
        var top: Bool?
        var id: String { word }
    }
    struct HotWrap: Codable { var items: [HotItem]? }
    struct UserRow: Codable, Identifiable {
        var id: String
        var name: String
        var avatar: String?
        var douyinId: String?
        var fanText: String?
        var verified: Bool?
    }
    struct TopicRow: Codable, Identifiable {
        var name: String
        var count: Int?
        var id: String { name }
    }
    struct Result: Codable {
        var videos: [RemoteVideo]?
        var users: [UserRow]?
        var topics: [TopicRow]?
    }

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            if submitted.isEmpty {
                discover
            } else {
                results
            }
        }
        .background(Color.black.ignoresSafeArea())
        .task { await loadHot() }
        .onAppear { focused = true }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 6) {
                SearchIcon(size: 15, color: Color(white: 0.6))
                TextField("", text: $text)
                    .placeholder(when: text.isEmpty) {
                        Text("搜索你感兴趣的内容").foregroundColor(Color(white: 0.45))
                    }
                    .font(pf(14.5))
                    .foregroundColor(.white)
                    .focused($focused)
                    .submitLabel(.search)
                    .onSubmit { search(text) }
                if !text.isEmpty {
                    Button { text = ""; submitted = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(Color(white: 0.4))
                    }
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 38)
            .background(RoundedRectangle(cornerRadius: 19).fill(Color(white: 0.14)))

            Button("取消", action: onClose)
                .font(pf(14.5))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var discover: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !history.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("搜索历史").font(pf(14.5, .semibold)).foregroundColor(.white)
                            Spacer()
                            Button { history = [] } label: {
                                Image(systemName: "trash").font(.system(size: 13))
                                    .foregroundColor(Color(white: 0.45))
                            }
                        }
                        FlowTags(items: history) { w in search(w) }
                    }
                }
                VStack(alignment: .leading, spacing: 10) {
                    Text("猜你想搜").font(pf(14.5, .semibold)).foregroundColor(.white)
                    FlowTags(items: (hot.prefix(6)).map { $0.word }) { w in search(w) }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("抖音热搜").font(pf(14.5, .semibold)).foregroundColor(.white)
                        .padding(.bottom, 8)
                    ForEach(hot) { h in
                        HotRow(item: h) { search(h.word) }
                        if h.rank < hot.count { Divider().background(Color(white: 0.1)) }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 40)
        }
    }

    private var results: some View {
        VStack(spacing: 0) {
            HStack(spacing: 22) {
                ForEach(0..<3, id: \.self) { i in
                    Button { tab = i } label: {
                        Text(["视频", "用户", "话题"][i])
                            .font(pf(14.5, tab == i ? .semibold : .regular))
                            .foregroundColor(tab == i ? .white : Color(white: 0.55))
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 40)

            if tab == 0 {
                if videos.isEmpty { emptyRow("没有找到相关视频") } else { grid }
            } else if tab == 1 {
                userList
            } else {
                topicList
            }
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)], spacing: 2) {
                ForEach(videos) { v in
                    PosterCell(video: v)
                }
            }
            .padding(.bottom, 40)
        }
    }

    private var userList: some View {
        ScrollView {
            VStack(spacing: 0) {
                if users.isEmpty { emptyRow("没有找到相关用户") }
                ForEach(users) { u in
                    UserResultRow(user: u)
                }
            }
        }
    }

    private var topicList: some View {
        ScrollView {
            VStack(spacing: 0) {
                if topics.isEmpty { emptyRow("没有找到相关话题") }
                ForEach(topics) { t in
                    TopicResultRow(topic: t)
                }
            }
        }
    }

    private func emptyRow(_ text: String) -> some View {
        VStack {
            Spacer(minLength: 40)
            Text(text).font(pf(14)).foregroundColor(Color(white: 0.5))
            Spacer()
        }
    }

    private func rankColor(_ r: Int) -> Color {
        if r == 1 { return Color(red: 1, green: 0.3, blue: 0.35) }
        if r == 2 { return Color(red: 1, green: 0.6, blue: 0.2) }
        if r == 3 { return Color(red: 1, green: 0.8, blue: 0.25) }
        return Color(white: 0.5)
    }

    private func humanCount(_ n: Int) -> String {
        if n >= 10000 { return String(format: "%.1f万", Double(n) / 10000) }
        return String(n)
    }

    private func search(_ word: String) {
        let w = word.trimmingCharacters(in: .whitespaces)
        guard !w.isEmpty else { return }
        submitted = w
        text = w
        if !history.contains(w) { history.insert(w, at: 0) }
        focused = false
        Task {
            guard let q = w.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return }
            if let r = try? await Api.get("/api/search?q=" + q, as: Result.self) {
                videos = (r.videos ?? []).enumerated().map { Store.fromRemote($0.element, index: $0.offset) }
                users = r.users ?? []
                topics = r.topics ?? []
            }
        }
    }

    private func loadHot() async {
        if let r = try? await Api.get("/api/search/hot", as: HotWrap.self) {
            hot = r.items ?? []
        }
    }
}

/// 热搜榜的一行
struct HotRow: View {
    let item: SearchPage2.HotItem
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Text(String(item.rank))
                    .font(pf(14, .semibold))
                    .foregroundColor(rankColor)
                    .frame(width: 20, alignment: .leading)
                Text(item.word).font(pf(14.5)).foregroundColor(.white)
                if item.top == true {
                    Text("热")
                        .font(pf(10, .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .frame(height: 15)
                        .background(RoundedRectangle(cornerRadius: 3).fill(Theme.primary))
                }
                Spacer()
                if let n = item.hot {
                    Text(hotText(n)).font(pf(12)).foregroundColor(Color(white: 0.45))
                }
            }
            .frame(height: 42)
            .contentShape(Rectangle())
        }
    }

    private var rankColor: Color {
        switch item.rank {
        case 1: return Color(red: 1, green: 0.3, blue: 0.35)
        case 2: return Color(red: 1, green: 0.6, blue: 0.2)
        case 3: return Color(red: 1, green: 0.8, blue: 0.25)
        default: return Color(white: 0.5)
        }
    }

    private func hotText(_ n: Int) -> String {
        if n >= 10000 { return String(format: "%.1f万", Double(n) / 10000) }
        return String(n)
    }
}

/// 搜索结果里的一行用户
struct UserResultRow: View {
    let user: SearchPage2.UserRow

    var body: some View {
        HStack(spacing: 12) {
            AvatarView(name: user.avatar ?? "")
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(user.name).font(pf(15, .medium)).foregroundColor(.white)
                Text(subtitle).font(pf(12)).foregroundColor(Color(white: 0.5))
            }
            Spacer()
            Text("关注")
                .font(pf(13, .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .frame(height: 30)
                .background(Capsule().fill(Theme.primary))
        }
        .padding(.horizontal, 16)
        .frame(height: 72)
    }

    private var subtitle: String {
        "抖音号：" + (user.douyinId ?? "") + " · " + (user.fanText ?? "0") + " 粉丝"
    }
}

/// 搜索结果里的一行话题
struct TopicResultRow: View {
    let topic: SearchPage2.TopicRow

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "number")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(Theme.primary)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color(white: 0.13)))
            VStack(alignment: .leading, spacing: 4) {
                Text("# " + topic.name).font(pf(15, .medium)).foregroundColor(.white)
                Text(countText).font(pf(12)).foregroundColor(Color(white: 0.5))
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .frame(height: 68)
    }

    private var countText: String {
        let n = topic.count ?? 0
        if n >= 10000 { return String(format: "%.1f万 次播放", Double(n) / 10000) }
        return "\(n) 次播放"
    }
}

/// 一行可以自动换行的标签（搜索历史/猜你想搜）
struct FlowTags: View {
    let items: [String]
    var onTap: (String) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { t in
                Button { onTap(t) } label: {
                    Text(t)
                        .font(pf(13))
                        .foregroundColor(Color(white: 0.85))
                        .lineLimit(1)
                        .padding(.horizontal, 12)
                        .frame(height: 32)
                        .background(Capsule().fill(Color(white: 0.14)))
                }
            }
        }
    }
}
