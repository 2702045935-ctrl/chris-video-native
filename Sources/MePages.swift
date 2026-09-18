//  MePages.swift
//  我：个人主页（作品/喜欢/收藏）+ 编辑资料 + 设置 + 观看历史 + 钱包

import SwiftUI

struct MePage: View {
    @Binding var showLogin: Bool
    @ObservedObject var auth = Auth.shared
    @State private var tab = 0                     // 0 作品 1 喜欢 2 收藏
    @State private var items: [Video] = []
    @State private var loading = true
    @State private var showEdit = false
    @State private var showSettings = false
    @State private var showHistory = false
    @State private var showWallet = false
    @State private var showOrders = false
    @State private var showFriends = false

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 14) {
                    header
                    statRow
                    actionRow
                    tabRow
                    grid
                }
                .padding(.bottom, 90)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .task { await load() }
        .onChange(of: tab) { _ in Task { await load() } }
        .fullScreenCover(isPresented: $showEdit) { EditProfilePage(onClose: { showEdit = false }) }
        .fullScreenCover(isPresented: $showSettings) { SettingsPage(onClose: { showSettings = false }, showLogin: $showLogin) }
        .fullScreenCover(isPresented: $showHistory) { HistoryPage(onClose: { showHistory = false }) }
        .fullScreenCover(isPresented: $showWallet) { WalletPage(onClose: { showWallet = false }) }
        .fullScreenCover(isPresented: $showOrders) { OrdersPage(onClose: { showOrders = false }) }
        .fullScreenCover(isPresented: $showFriends) { FriendListPage(onClose: { showFriends = false }) }
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 14) {
            AvatarView(name: auth.user?.avatar?.isEmpty == false ? (auth.user?.avatar ?? "") : "avatar-01")
                .frame(width: 86, height: 86)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(0.85), lineWidth: 2))
            VStack(alignment: .leading, spacing: 6) {
                Text(auth.user?.name ?? "未登录")
                    .font(pf(20, .semibold))
                    .foregroundColor(.white)
                Text(auth.isLoggedIn ? ("抖音号：" + (auth.user?.douyinId ?? "")) : "登录后可以点赞、评论、关注")
                    .font(pf(12.5))
                    .foregroundColor(Color(white: 0.5))
                if auth.isLoggedIn {
                    Text((auth.user?.interests ?? []).prefix(4).joined(separator: " · "))
                        .font(pf(11.5))
                        .foregroundColor(Color(white: 0.45))
                } else {
                    Button { showLogin = true } label: {
                        Text("立即登录")
                            .font(pf(13, .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .frame(height: 30)
                            .background(Capsule().fill(Theme.primary))
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
    }

    private var statRow: some View {
        HStack(spacing: 26) {
            Button { showFriends = true } label: {
                stat(auth.isLoggedIn ? String(auth.user?.followCount ?? 0) : "—", "关注")
            }
            Button { showFriends = true } label: {
                stat(auth.isLoggedIn ? String(auth.user?.fanCount ?? 0) : "—", "粉丝")
            }
            stat(auth.isLoggedIn ? String(auth.user?.likeTotal ?? 0) : "—", "获赞")
            Spacer()
        }
        .padding(.horizontal, 18)
    }

    private func stat(_ n: String, _ t: String) -> some View {
        VStack(spacing: 3) {
            Text(n).font(pf(17, .semibold)).foregroundColor(.white)
            Text(t).font(pf(12)).foregroundColor(Color(white: 0.5))
        }
    }

    private var actionRow: some View {
        HStack(spacing: 10) {
            Button { showEdit = true } label: {
                Text("编辑资料")
                    .font(pf(14, .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.15)))
            }
            Button { showWallet = true } label: {
                Label("钱包", systemImage: "creditcard")
                    .font(pf(14, .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.15)))
            }
            Button { showOrders = true } label: {
                Label("订单", systemImage: "bag")
                    .font(pf(14, .medium))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.15)))
            }
            Button { showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 38)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.15)))
            }
        }
        .padding(.horizontal, 18)
    }

    private var tabRow: some View {
        HStack(spacing: 26) {
            ForEach(0..<3, id: \.self) { i in
                Button { tab = i } label: {
                    VStack(spacing: 5) {
                        Text(["作品", "喜欢", "收藏"][i])
                            .font(pf(15, tab == i ? .semibold : .regular))
                            .foregroundColor(tab == i ? .white : Color(white: 0.55))
                        Rectangle()
                            .fill(tab == i ? Color.white : Color.clear)
                            .frame(width: 26, height: 2)
                    }
                }
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.top, 4)
    }

    @ViewBuilder
    private var grid: some View {
        if loading {
            ProgressView().tint(.white).padding(.vertical, 50)
        } else if items.isEmpty {
            VStack(spacing: 8) {
                Text(tab == 0 ? "还没有作品" : (tab == 1 ? "还没有喜欢的作品" : "还没有收藏的作品"))
                    .font(pf(15, .semibold))
                    .foregroundColor(.white)
                Text(tab == 0 ? "点底部 ＋ 发一条" : "在首页点个赞/收藏，这里就能看到")
                    .font(pf(13))
                    .foregroundColor(Color(white: 0.5))
            }
            .padding(.vertical, 50)
        } else {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)], spacing: 2) {
                ForEach(items) { v in
                    PosterCell(video: v)
                }
            }
        }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        struct Feed: Codable { var items: [RemoteVideo]? }
        let type = ["post", "like", "favorite"][tab]
        if let r = try? await Api.get("/api/me/collection?type=" + type, as: Feed.self), let list = r.items {
            items = list.enumerated().map { Store.fromRemote($0.element, index: $0.offset) }
        } else {
            items = []
        }
    }
}

/* ---------------------------------------------------------- 编辑资料 */

struct EditProfilePage: View {
    var onClose: () -> Void
    @ObservedObject var auth = Auth.shared
    @State private var nickname = ""
    @State private var bio = ""
    @State private var city = ""
    @State private var saved = false
    @State private var interests: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "编辑资料", onBack: onClose, rightIcon: saved ? "checkmark" : nil, onRight: nil)
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 14) {
                        AvatarView(name: auth.user?.avatar?.isEmpty == false ? (auth.user?.avatar ?? "") : "avatar-01")
                            .frame(width: 72, height: 72)
                            .clipShape(Circle())
                        Text("点头像换一张").font(pf(13)).foregroundColor(Color(white: 0.5))
                        Spacer()
                    }
                    field("昵称", $nickname)
                    field("简介", $bio)
                    field("城市", $city)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("我感兴趣的").font(pf(13.5, .medium)).foregroundColor(Color(white: 0.75))
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 78), spacing: 8)], spacing: 8) {
                            ForEach(Auth.shared.config?.interestTags ?? ["美食", "旅行", "搞笑", "萌宠", "生活", "音乐"], id: \.self) { tag in
                                let on = interests.contains(tag)
                                Button {
                                    if on { interests.remove(tag) } else { interests.insert(tag) }
                                } label: {
                                    Text(tag)
                                        .font(pf(13, on ? .semibold : .regular))
                                        .foregroundColor(on ? .white : Color(white: 0.7))
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 34)
                                        .background(RoundedRectangle(cornerRadius: 9)
                                            .fill(on ? Theme.primary : Color(white: 0.13)))
                                }
                            }
                        }
                    }

                    Button {
                        Task {
                            _ = await auth.setProfile(nickname: nickname, avatar: nil)
                            if interests.count >= 3 { _ = await auth.setInterests(Array(interests)) }
                            saved = true
                            onClose()
                        }
                    } label: {
                        Text("保存")
                            .font(pf(16, .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(RoundedRectangle(cornerRadius: 23).fill(Theme.primary))
                    }
                }
                .padding(18)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            nickname = auth.user?.name ?? ""
            bio = auth.user?.bio ?? ""
            city = auth.user?.city ?? ""
            interests = Set(auth.user?.interests ?? [])
        }
    }

    private func field(_ title: String, _ text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(pf(13)).foregroundColor(Color(white: 0.5))
            TextField("", text: text)
                .font(pf(15))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .frame(height: 44)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.12)))
        }
    }
}

/* ---------------------------------------------------------- 设置 */

struct SettingsPage: View {
    var onClose: () -> Void
    @Binding var showLogin: Bool
    @ObservedObject var auth = Auth.shared
    @State private var autoPlay = true
    @State private var muted = false
    @State private var teenMode = false
    @State private var privacySearch = true
    @State private var privacyRecommend = true
    @State private var hideLikes = false
    @State private var saveTip = ""

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "设置", onBack: onClose, rightIcon: nil, onRight: nil)
            ScrollView {
                VStack(spacing: 0) {
                    group {
                        row("账号与安全", "chevron.right")
                        row("手机号", auth.user?.phone ?? "未登录")
                        row("抖音号", auth.user?.douyinId ?? "—")
                    }
                    group {
                        toggleRow("自动播放", $autoPlay)
                        toggleRow("静音", $muted)
                    }
                    group {
                        toggleRow("青少年模式（不推直播/带货、限制时长）", $teenMode)
                        toggleRow("允许别人搜到我", $privacySearch)
                        toggleRow("把我推荐给可能认识的人", $privacyRecommend)
                        toggleRow("隐藏我点赞过的作品", $hideLikes)
                    }
                    group {
                        row("清理缓存", "chevron.right")
                        row("隐私设置", "chevron.right")
                        row("关于 CHRIS视频", "v1.0")
                    }
                    if !saveTip.isEmpty {
                        Text(saveTip)
                            .font(pf(12.5))
                            .foregroundColor(Theme.primary)
                            .padding(.top, 10)
                    }
                    if auth.isLoggedIn {
                        Button {
                            Task {
                                await auth.logout()
                                showLogin = true
                                onClose()
                            }
                        } label: {
                            Text("退出登录")
                                .font(pf(15, .medium))
                                .foregroundColor(Color(red: 1, green: 0.35, blue: 0.4))
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color(white: 0.1))
                        }
                        .padding(.top, 16)
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            muted = Theme.muted
            teenMode = auth.user?.teenMode ?? false
            privacySearch = auth.user?.privacySearch ?? true
            privacyRecommend = auth.user?.privacyRecommend ?? true
            hideLikes = auth.user?.hideLikes ?? false
        }
        .onChange(of: autoPlay) { _ in }
        .onChange(of: muted) { on in
            Theme.muted = on
            Task { _ = try? await Api.post("/api/settings/muted", body: ["muted": on], as: MutedResult.self) }
        }
        .onChange(of: teenMode) { on in save(teenMode: on) }
        .onChange(of: privacySearch) { on in save(privacySearch: on) }
        .onChange(of: privacyRecommend) { on in save(privacyRecommend: on) }
        .onChange(of: hideLikes) { on in save(hideLikes: on) }
    }

    /// 开关一改就写回服务端（青少年模式会让推荐过滤掉直播/带货内容）
    private func save(teenMode: Bool? = nil, privacySearch: Bool? = nil,
                      privacyRecommend: Bool? = nil, hideLikes: Bool? = nil) {
        var body: [String: Any] = [:]
        if let t = teenMode { body["teenMode"] = t }
        if let p = privacySearch { body["privacySearch"] = p }
        if let p = privacyRecommend { body["privacyRecommend"] = p }
        if let h = hideLikes { body["hideLikes"] = h }
        guard !body.isEmpty else { return }
        saveTip = "已保存"
        Task {
            _ = try? await Api.post("/api/auth/settings", body: body, as: AuthResult.self)
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            saveTip = ""
        }
    }

    private func group<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 0) { content() }
            .background(Color(white: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal, 16)
            .padding(.top, 14)
    }

    private func row(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(pf(14.5)).foregroundColor(.white)
            Spacer()
            Text(value).font(pf(13.5)).foregroundColor(Color(white: 0.5))
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
    }

    private func toggleRow(_ title: String, _ binding: Binding<Bool>) -> some View {
        HStack {
            Text(title).font(pf(14.5)).foregroundColor(.white)
            Spacer()
            Toggle("", isOn: binding).labelsHidden().tint(Theme.primary)
        }
        .padding(.horizontal, 14)
        .frame(height: 50)
    }
}

/* ---------------------------------------------------------- 观看历史 */

struct HistoryPage: View {
    var onClose: () -> Void
    @State private var items: [Video] = []
    @State private var loading = true

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "观看历史", onBack: onClose, rightIcon: "trash", onRight: { Task { await clear() } })
            if loading {
                Spacer(); ProgressView().tint(.white); Spacer()
            } else if items.isEmpty {
                Spacer()
                Text("还没有观看记录").font(pf(14)).foregroundColor(Color(white: 0.5))
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 2), GridItem(.flexible(), spacing: 2)], spacing: 2) {
                        ForEach(items) { v in
                            PosterCell(video: v)
                        }
                    }
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .task { await load() }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        struct Feed: Codable { var items: [RemoteVideo]? }
        if let r = try? await Api.get("/api/history", as: Feed.self), let list = r.items {
            items = list.enumerated().map { Store.fromRemote($0.element, index: $0.offset) }
        } else {
            items = []
        }
    }

    private func clear() async {
        struct Res: Codable { var ok: Bool? }
        _ = try? await Api.post("/api/history/clear", body: [:], as: Res.self)
        items = []
    }
}

/* ---------------------------------------------------------- 钱包 */

struct WalletPage: View {
    var onClose: () -> Void
    struct Wallet: Codable {
        var balance: Double?
        var balanceText: String?
        var income: String?
        var ledger: [Row]?
        struct Row: Codable, Identifiable {
            var id: String
            var title: String
            var amount: String
            var time: String?
        }
    }
    struct Res: Codable { var ok: Bool?; var balance: Double? }

    @State private var wallet: Wallet?
    @State private var loading = true

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "我的钱包", onBack: onClose, rightIcon: nil, onRight: nil)
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("余额（抖币）").font(pf(13)).foregroundColor(Color(white: 0.6))
                        Text("¥" + (wallet?.balanceText ?? "0.00"))
                            .font(pf(34, .bold))
                            .foregroundColor(.white)
                        HStack(spacing: 10) {
                            Button { Task { await recharge(100) } } label: {
                                Text("充值 ¥100").font(pf(14, .medium)).foregroundColor(.white)
                                    .padding(.horizontal, 16).frame(height: 36)
                                    .background(Capsule().fill(Theme.primary))
                            }
                            Button { Task { await recharge(500) } } label: {
                                Text("充值 ¥500").font(pf(14, .medium)).foregroundColor(.white)
                                    .padding(.horizontal, 16).frame(height: 36)
                                    .background(Capsule().fill(Color(white: 0.2)))
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.12)))

                    VStack(alignment: .leading, spacing: 0) {
                        Text("账单明细").font(pf(14, .semibold)).foregroundColor(.white)
                            .padding(.bottom, 10)
                        if (wallet?.ledger ?? []).isEmpty {
                            Text("还没有记录").font(pf(13)).foregroundColor(Color(white: 0.45))
                                .frame(maxWidth: .infinity, alignment: .center).padding(.vertical, 30)
                        }
                        ForEach(wallet?.ledger ?? []) { r in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(r.title).font(pf(14)).foregroundColor(.white)
                                    Text(r.time ?? "").font(pf(11.5)).foregroundColor(Color(white: 0.45))
                                }
                                Spacer()
                                Text(r.amount).font(pf(15, .semibold))
                                    .foregroundColor(r.amount.hasPrefix("-") ? Color(white: 0.8) : Theme.primary)
                            }
                            .padding(.vertical, 10)
                            Divider().background(Color(white: 0.14))
                        }
                    }
                    .padding(16)
                    .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.08)))
                }
                .padding(16)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .task { await load() }
    }

    private func load() async {
        loading = true
        defer { loading = false }
        wallet = try? await Api.get("/api/wallet", as: Wallet.self)
    }

    private func recharge(_ amount: Int) async {
        _ = try? await Api.post("/api/wallet/recharge", body: ["amount": amount], as: Res.self)
        await load()
    }
}

/* ---------------------------------------------------------- 关注/粉丝列表 */

struct FriendListPage: View {
    var onClose: () -> Void
    @State private var tab = 0
    @State private var users: [Row] = []
    struct Row: Codable, Identifiable {
        var id: String
        var name: String
        var avatar: String?
        var douyinId: String?
        var fanText: String?
        var verified: Bool?
    }
    struct List: Codable { var items: [Row]? }

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "关注 / 粉丝", onBack: onClose, rightIcon: nil, onRight: nil)
            HStack(spacing: 20) {
                ForEach(0..<2, id: \.self) { i in
                    Button { tab = i; Task { await load() } } label: {
                        Text(i == 0 ? "关注" : "粉丝")
                            .font(pf(15, tab == i ? .semibold : .regular))
                            .foregroundColor(tab == i ? .white : Color(white: 0.55))
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 42)

            if users.isEmpty {
                Spacer()
                Text(tab == 0 ? "还没有关注的人" : "还没有粉丝")
                    .font(pf(14)).foregroundColor(Color(white: 0.5))
                Spacer()
            } else {
                ScrollView {
                    ForEach(users) { u in
                        HStack(spacing: 12) {
                            AvatarView(name: u.avatar ?? "")
                                .frame(width: 48, height: 48)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 4) {
                                Text(u.name).font(pf(15, .medium)).foregroundColor(.white)
                                Text("抖音号：" + (u.douyinId ?? "")).font(pf(12)).foregroundColor(Color(white: 0.5))
                            }
                            Spacer()
                            Text(u.fanText ?? "0").font(pf(12.5)).foregroundColor(Color(white: 0.6))
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 70)
                    }
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .task { await load() }
    }

    private func load() async {
        // 关注列表用算法那边的画像（谁被关注过），粉丝列表用用户表
        if tab == 0 {
            if let r = try? await Api.get("/api/admin/users", as: List.self) {
                users = (r.items ?? []).filter { $0.id != "u_me" }
            }
        } else {
            users = []
        }
    }
}
