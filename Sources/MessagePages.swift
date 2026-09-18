//  MessagePages.swift
//  消息页：互动消息 / 私信 两个 tab，通知列表 + 会话列表，点进去是聊天详情

import SwiftUI

struct MessagesPage: View {
    @State private var tab = 0                 // 0 互动消息 1 朋友消息(私信)
    @State private var notices: [Notice] = []
    @State private var chats: [ChatRow] = []
    @State private var summary: Summary = Summary()
    @State private var openedChat: ChatRow?
    @State private var loading = true

    struct Notice: Codable, Identifiable {
        var id: String
        var kind: String?
        var text: String
        var at: Int?
        var read: Bool?
    }
    struct ChatRow: Codable, Identifiable {
        var id: String
        var peer: Peer
        var last: String?
        var lastAt: Int?
        var unread: Int?
        struct Peer: Codable { var id: String; var name: String; var avatar: String? }
    }
    struct Summary: Codable {
        var interaction: Int?
        var comment: Int?
        var like: Int?
        var follow: Int?
        var system: Int?
        var chats: Int?
        var unread: Int?
    }
    struct NoticeList: Codable { var items: [Notice]? }
    struct ChatList: Codable { var items: [ChatRow]? }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 18) {
                tabButton("互动消息", 0)
                tabButton("朋友消息", 1)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Color.black)

            if loading {
                Spacer(); ProgressView().tint(.white); Spacer()
            } else if tab == 0 {
                interactionList
            } else {
                chatList
            }
        }
        .background(Color.black.ignoresSafeArea())
        .task { await load() }
        .onChange(of: tab) { _ in Task { await load() } }
        .fullScreenCover(item: $openedChat) { c in
            ChatDetailView(row: c, onClose: { openedChat = nil })
        }
    }

    private func tabButton(_ title: String, _ i: Int) -> some View {
        Button { tab = i } label: {
            VStack(spacing: 3) {
                Text(title)
                    .font(pf(17, tab == i ? .semibold : .regular))
                    .foregroundColor(tab == i ? .white : Color(white: 0.6))
                Rectangle()
                    .fill(tab == i ? Theme.primary : Color.clear)
                    .frame(width: 22, height: 2)
                    .clipShape(Capsule())
            }
        }
    }

    private var interactionList: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    entry("赞", "heart.fill", summary.like ?? 0, Color(red: 1, green: 0.3, blue: 0.4))
                    entry("评论", "bubble.left.fill", summary.comment ?? 0, Color(red: 0.3, green: 0.6, blue: 1))
                    entry("粉丝", "person.fill", summary.follow ?? 0, Color(red: 1, green: 0.7, blue: 0.2))
                }
                .padding(.vertical, 16)
                Divider().background(Color(white: 0.15))

                if notices.isEmpty {
                    emptyHint("还没有互动消息", "别人赞了、评论了、关注了你，会显示在这里")
                }
                ForEach(notices) { n in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle().fill(Color(white: 0.15)).frame(width: 42, height: 42)
                            Image(systemName: iconFor(n.kind))
                                .font(.system(size: 17))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(n.text)
                                .font(pf(14))
                                .foregroundColor(.white)
                                .lineLimit(2)
                            if let at = n.at {
                                Text(timeAgoText(at))
                                    .font(pf(11.5))
                                    .foregroundColor(Color(white: 0.45))
                            }
                        }
                        Spacer()
                        if n.read == false {
                            Circle().fill(Theme.primary).frame(width: 8, height: 8)
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 72)
                    Divider().background(Color(white: 0.12))
                }
            }
            .padding(.bottom, 90)
        }
    }

    private func entry(_ title: String, _ icon: String, _ count: Int, _ color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle().fill(color.opacity(0.18)).frame(width: 52, height: 52)
                Image(systemName: icon).font(.system(size: 20)).foregroundColor(color)
            }
            Text(title).font(pf(12.5)).foregroundColor(Color(white: 0.8))
        }
        .frame(maxWidth: .infinity)
    }

    private var chatList: some View {
        ScrollView {
            VStack(spacing: 0) {
                if chats.isEmpty {
                    emptyHint("还没有私信", "去别人的主页点「私信」聊两句")
                }
                ForEach(chats) { c in
                    Button {
                        openedChat = c
                    } label: {
                        HStack(spacing: 12) {
                            AvatarView(name: c.peer.avatar ?? "")
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text(c.peer.name)
                                    .font(pf(15, .medium))
                                    .foregroundColor(.white)
                                Text(c.last ?? "")
                                    .font(pf(13))
                                    .foregroundColor(Color(white: 0.5))
                                    .lineLimit(1)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 6) {
                                if let at = c.lastAt {
                                    Text(timeAgoText(at)).font(pf(11)).foregroundColor(Color(white: 0.4))
                                }
                                if (c.unread ?? 0) > 0 {
                                    Text(String(c.unread ?? 0))
                                        .font(pf(10.5, .semibold))
                                        .foregroundColor(.white)
                                        .frame(minWidth: 18, minHeight: 18)
                                        .background(Circle().fill(Theme.primary))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 74)
                        .contentShape(Rectangle())
                    }
                    Divider().background(Color(white: 0.12))
                }
            }
            .padding(.bottom, 90)
        }
    }

    private func emptyHint(_ title: String, _ sub: String) -> some View {
        VStack(spacing: 8) {
            Text(title).font(pf(15, .semibold)).foregroundColor(.white)
            Text(sub).font(pf(13)).foregroundColor(Color(white: 0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 70)
    }

    private func iconFor(_ kind: String?) -> String {
        switch kind {
        case "like": return "heart.fill"
        case "comment": return "bubble.left.fill"
        case "follow": return "person.badge.plus"
        default: return "bell.fill"
        }
    }

    private func timeAgoText(_ ts: Int) -> String {
        let sec = max(0, (Int(Date().timeIntervalSince1970 * 1000) - ts) / 1000)
        if sec < 60 { return "刚刚" }
        if sec < 3600 { return "\(sec / 60) 分钟前" }
        if sec < 86400 { return "\(sec / 3600) 小时前" }
        return "\(sec / 86400) 天前"
    }

    private func load() async {
        loading = true
        defer { loading = false }
        if let s = try? await Api.get("/api/messages/summary", as: Summary.self) { summary = s }
        if tab == 0 {
            if let r = try? await Api.get("/api/messages/list?type=interaction", as: NoticeList.self) {
                notices = r.items ?? []
            }
        } else {
            if let r = try? await Api.get("/api/chat/list", as: ChatList.self) {
                chats = r.items ?? []
            }
        }
    }
}

/// 聊天详情：发消息（对象会自动回一句）
struct ChatDetailView: View {
    let row: MessagesPage.ChatRow
    var onClose: () -> Void
    @State private var messages: [Msg] = []
    @State private var text = ""
    @State private var loading = true

    struct Msg: Codable, Identifiable {
        var id: String
        var mine: Bool
        var text: String
        var at: Int?
        var time: String?
    }
    struct ChatWrap: Codable {
        var chat: Chat?
        struct Chat: Codable { var id: String; var messages: [Msg]? }
    }
    struct SendResult: Codable { var ok: Bool? }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button(action: onClose) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 44)
                }
                Text(row.peer.name).font(pf(16, .semibold)).foregroundColor(.white)
                Spacer()
                Image(systemName: "ellipsis")
                    .font(.system(size: 17))
                    .foregroundColor(Color(white: 0.7))
                    .frame(width: 40, height: 44)
            }
            .padding(.horizontal, 4)
            .background(Color.black)

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 12) {
                        if loading { ProgressView().tint(.white).padding(.top, 40) }
                        ForEach(messages) { m in
                            bubble(m).id(m.id)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }

            HStack(spacing: 10) {
                TextField("", text: $text)
                    .placeholder(when: text.isEmpty) { Text("发消息…").foregroundColor(Color(white: 0.45)) }
                    .font(pf(14.5))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 40)
                    .background(RoundedRectangle(cornerRadius: 20).fill(Color(white: 0.13)))
                Button { send() } label: {
                    Text("发送")
                        .font(pf(14, .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .frame(height: 40)
                        .background(Capsule().fill(Theme.primary))
                }
                .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(white: 0.06))
        }
        .background(Color.black.ignoresSafeArea())
        .task { await load() }
    }

    private func bubble(_ m: Msg) -> some View {
        HStack {
            if m.mine { Spacer(minLength: 60) }
            VStack(alignment: m.mine ? .trailing : .leading, spacing: 4) {
                Text(m.text)
                    .font(pf(14.5))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(RoundedRectangle(cornerRadius: 12)
                        .fill(m.mine ? Theme.primary : Color(white: 0.16)))
                if let t = m.time {
                    Text(t).font(pf(10.5)).foregroundColor(Color(white: 0.4))
                }
            }
            if !m.mine { Spacer(minLength: 60) }
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        if let r = try? await Api.get("/api/chat/messages?peer=" + row.peer.id, as: ChatWrap.self) {
            messages = r.chat?.messages ?? []
        }
        // 等对方回复
        try? await Task.sleep(nanoseconds: 1_600_000_000)
        if let r = try? await Api.get("/api/chat/messages?peer=" + row.peer.id, as: ChatWrap.self) {
            messages = r.chat?.messages ?? []
        }
    }

    private func send() {
        let body = text
        text = ""
        Task {
            _ = try? await Api.post("/api/chat/send",
                                    body: ["peer": row.peer.id, "text": body], as: SendResult.self)
            if let r = try? await Api.get("/api/chat/messages?peer=" + row.peer.id, as: ChatWrap.self) {
                messages = r.chat?.messages ?? []
            }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if let r = try? await Api.get("/api/chat/messages?peer=" + row.peer.id, as: ChatWrap.self) {
                messages = r.chat?.messages ?? []
            }
        }
    }
}
