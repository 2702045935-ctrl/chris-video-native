//  LivePages.swift
//  直播：直播广场（双列大卡）+ 直播间（弹幕、礼物、小黄车、在线人数）

import SwiftUI

struct LiveRoomRow: Codable, Identifiable {
    var id: String
    var name: String
    var title: String
    var onlineText: String?
    var cover: String?
    var tag: String?
}

struct LiveListPage: View {
    var onClose: () -> Void
    @State private var rooms: [LiveRoomRow] = []
    @State private var opened: LiveRoomRow?
    struct Wrap: Codable { var items: [LiveRoomRow]? }

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "直播广场", onBack: onClose, rightIcon: nil, onRight: nil)
            if rooms.isEmpty {
                Spacer()
                Text("还没有直播").font(pf(14)).foregroundColor(Color(white: 0.5))
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(rooms) { r in
                            Button { opened = r } label: { card(r) }
                        }
                    }
                    .padding(10)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .task { await load() }
        .fullScreenCover(item: $opened) { r in
            LiveRoomPage(room: r, onClose: { opened = nil })
        }
    }

    private func card(_ r: LiveRoomRow) -> some View {
        ZStack(alignment: .topLeading) {
            coverImage(r.cover)
                .frame(height: 230)
                .clipped()
            LinearGradient(colors: [Color.clear, Color.black.opacity(0.6)],
                           startPoint: .center, endPoint: .bottom)
            HStack(spacing: 4) {
                Circle().fill(Theme.primary).frame(width: 6, height: 6)
                Text(r.onlineText ?? "0").font(pf(11, .medium)).foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .frame(height: 22)
            .background(Capsule().fill(Color.black.opacity(0.45)))
            .padding(8)

            VStack {
                Spacer()
                HStack(spacing: 6) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(r.name).font(pf(13, .semibold)).foregroundColor(.white)
                        Text(r.title).font(pf(11.5)).foregroundColor(Color(white: 0.8)).lineLimit(1)
                    }
                    Spacer()
                }
                .padding(8)
            }
        }
        .frame(height: 230)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private func coverImage(_ path: String?) -> some View {
        if let p = path, !p.isEmpty {
            let url = p.hasPrefix("http") ? p : ServerConfig.base + "/uploads/" + p
            AsyncImage(url: URL(string: url)) { phase in
                if case .success(let img) = phase {
                    img.resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color(white: 0.15)
                }
            }
        } else {
            Color(white: 0.15)
        }
    }

    private func load() async {
        if let r = try? await Api.get("/api/live/rooms", as: Wrap.self) {
            rooms = r.items ?? []
        }
    }
}

struct LiveRoomPage: View {
    let room: LiveRoomRow
    var onClose: () -> Void

    struct Detail: Codable {
        var room: RoomInfo?
        var danmaku: [Danmaku]?
        var gifts: [Gift]?
        var cart: [CartItem]?
        struct RoomInfo: Codable {
            var id: String
            var name: String
            var title: String
            var onlineText: String?
            var cover: String?
        }
        struct Danmaku: Codable, Identifiable {
            var name: String
            var text: String
            var id: String { name + text }
        }
        struct Gift: Codable, Identifiable {
            var id: String
            var name: String
            var price: Int?
        }
        struct CartItem: Codable, Identifiable {
            var id: String
            var title: String
            var poster: String?
            var price: String?
        }
    }
    struct Res: Codable { var ok: Bool?; var balance: Double?; var error: String? }

    @State private var detail: Detail?
    @State private var danmakuLines: [String] = []
    @State private var text = ""
    @State private var showGifts = false
    @State private var showCart = false
    @State private var balance: Double?
    @State private var tip = ""

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            background
            VStack(spacing: 0) {
                topBar
                Spacer()
                danmakuList
                bottomBar
            }
            if showGifts { giftPanel }
            if showCart { cartPanel }
            if !tip.isEmpty { toast }
        }
        .task { await load() }
    }

    private var background: some View {
        Group {
            if let cover = detail?.room?.cover, !cover.isEmpty {
                let url = cover.hasPrefix("http") ? cover : ServerConfig.base + "/uploads/" + cover
                AsyncImage(url: URL(string: url)) { phase in
                    if case .success(let img) = phase {
                        img.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color(white: 0.1)
                    }
                }
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.35))
            } else {
                Color(white: 0.1).ignoresSafeArea()
            }
        }
    }

    private var topBar: some View {
        HStack(spacing: 10) {
            HStack(spacing: 8) {
                AvatarView(name: "")
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.white.opacity(0.6), lineWidth: 1.5))
                VStack(alignment: .leading, spacing: 2) {
                    Text(detail?.room?.name ?? room.name)
                        .font(pf(13.5, .semibold)).foregroundColor(.white)
                    Text((detail?.room?.onlineText ?? room.onlineText ?? "0") + " 人在线")
                        .font(pf(11)).foregroundColor(Color(white: 0.75))
                }
                Button { tip = "已关注" } label: {
                    Text("关注").font(pf(12, .semibold)).foregroundColor(.white)
                        .padding(.horizontal, 10).frame(height: 26)
                        .background(Capsule().fill(Theme.primary))
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 40)
            .background(Capsule().fill(Color.black.opacity(0.4)))

            Spacer()

            Button { showCart = true } label: {
                Image(systemName: "cart.fill")
                    .font(.system(size: 16)).foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold)).foregroundColor(.white)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.black.opacity(0.4)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 6)
    }

    private var danmakuList: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(danmakuLines.suffix(6), id: \.self) { line in
                Text(line)
                    .font(pf(13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.black.opacity(0.35)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            TextField("", text: $text)
                .placeholder(when: text.isEmpty) { Text("说点什么…").foregroundColor(Color(white: 0.5)) }
                .font(pf(14))
                .foregroundColor(.white)
                .onSubmit { sendDanmaku() }
                .padding(.horizontal, 12)
                .frame(height: 38)
                .background(Capsule().fill(Color.black.opacity(0.45)))
            Button { showGifts.toggle() } label: {
                Image(systemName: "gift.fill")
                    .font(.system(size: 17)).foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.black.opacity(0.45)))
            }
            Button { showCart = true } label: {
                Image(systemName: "bag.fill")
                    .font(.system(size: 16)).foregroundColor(.white)
                    .frame(width: 38, height: 38)
                    .background(Circle().fill(Color.black.opacity(0.45)))
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 14)
    }

    private var giftPanel: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("送礼物").font(pf(15, .semibold)).foregroundColor(.white)
                    Spacer()
                    if let b = balance {
                        Text("余额 ¥" + String(format: "%.0f", b))
                            .font(pf(12)).foregroundColor(Color(white: 0.6))
                    }
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 10)], spacing: 10) {
                    ForEach(detail?.gifts ?? []) { g in
                        Button { sendGift(g.id) } label: {
                            VStack(spacing: 4) {
                                Text(g.name).font(pf(13, .medium)).foregroundColor(.white)
                                Text("¥\(g.price ?? 0)").font(pf(11.5)).foregroundColor(Color(white: 0.6))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.15)))
                        }
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.1)))
            .padding(12)
        }
        .background(Color.black.opacity(0.35).ignoresSafeArea())
        .onTapGesture { showGifts = false }
    }

    private var cartPanel: some View {
        VStack {
            Spacer()
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("小黄车").font(pf(15, .semibold)).foregroundColor(.white)
                    Spacer()
                    Button { showCart = false } label: {
                        Image(systemName: "xmark").font(.system(size: 14)).foregroundColor(Color(white: 0.6))
                    }
                }
                ForEach(detail?.cart ?? []) { item in
                    HStack(spacing: 10) {
                        if let p = item.poster, !p.isEmpty {
                            let url = p.hasPrefix("http") ? p : ServerConfig.base + "/uploads/" + p
                            AsyncImage(url: URL(string: url)) { phase in
                                if case .success(let img) = phase {
                                    img.resizable().aspectRatio(contentMode: .fill)
                                } else {
                                    Color(white: 0.2)
                                }
                            }
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        } else {
                            Color(white: 0.2).frame(width: 44, height: 44)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title).font(pf(13.5)).foregroundColor(.white).lineLimit(1)
                            Text("¥" + (item.price ?? "0")).font(pf(12.5, .semibold)).foregroundColor(Theme.primary)
                        }
                        Spacer()
                        Text("讲解").font(pf(12, .medium)).foregroundColor(.white)
                            .padding(.horizontal, 10).frame(height: 28)
                            .background(Capsule().fill(Theme.primary))
                    }
                }
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color(white: 0.1)))
            .padding(12)
        }
        .background(Color.black.opacity(0.35).ignoresSafeArea())
    }

    private var toast: some View {
        VStack {
            Spacer()
            Text(tip)
                .font(pf(13.5))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .frame(height: 36)
                .background(Capsule().fill(Color.black.opacity(0.75)))
                .padding(.bottom, 120)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { tip = "" }
        }
    }

    private func sendDanmaku() {
        guard !text.isEmpty else { return }
        danmakuLines.append("我：" + text)
        text = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            danmakuLines.append("@小满：主播看到了！")
        }
    }

    private func sendGift(_ giftId: String) {
        Task {
            let r = try? await Api.post("/api/live/gift",
                                        body: ["roomId": room.id, "giftId": giftId, "count": 1], as: Res.self)
            if let b = r?.balance {
                balance = b
                tip = "礼物已送出 🎁"
                danmakuLines.append("我：送出了礼物🎁")
            } else {
                tip = r?.error ?? "余额不足，先去钱包充值"
            }
        }
    }

    private func load() async {
        if let d = try? await Api.get("/api/live/room?id=" + room.id, as: Detail.self) {
            detail = d
            danmakuLines = (d.danmaku ?? []).map { "\($0.name)：\($0.text)" }
        }
        struct Wallet: Codable { var balance: Double? }
        if let w = try? await Api.get("/api/wallet", as: Wallet.self) {
            balance = w.balance
        }
        startDanmaku()
    }

    private func startDanmaku() {
        let pool = ["@阿辰：这个真好玩", "@大熊：主播唱歌好听", "@灵子：刚来，发生了什么",
                    "@林深：666", "@晚风：已下单", "@拾光：主播在哪个城市"]
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { t in
            if !showGifts && !showCart {
                danmakuLines.append(pool.randomElement() ?? "")
            }
            if danmakuLines.count > 40 { t.invalidate() }
        }
    }
}
