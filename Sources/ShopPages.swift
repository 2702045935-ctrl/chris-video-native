//  ShopPages.swift
//  商城 / 团购：商品列表、商品详情、购物车、下单、我的订单

import SwiftUI

struct GoodRow: Codable, Identifiable {
    var id: String
    var title: String
    var price: Double?
    var stock: Int?
    var sold: Int?
    var poster: String?
    var tag: String?
    var desc: String?
}

/// 首页顶栏点「商城 / 团购」时用它打开商城页
struct ShopRoute: Identifiable {
    let id = UUID()
    var tag: String
}

struct ShopPage: View {
    var onClose: () -> Void
    var initialTag: String = "全部"
    @State private var goods: [GoodRow] = []
    @State private var tags: [String] = ["全部"]
    @State private var tag = "全部"
    @State private var keyword = ""
    @State private var detail: GoodRow?
    @State private var showCart = false
    @State private var showOrders = false
    @State private var cartCount = 0

    struct Wrap: Codable {
        var items: [GoodRow]?
        var tags: [String]?
    }
    struct CartWrap: Codable { var count: Int? }

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        VStack(spacing: 0) {
            header
            tagBar
            if goods.isEmpty {
                Spacer()
                Text("没有找到商品").font(pf(14)).foregroundColor(Color(white: 0.5))
                Spacer()
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(goods) { g in
                            Button { detail = g } label: { GoodCard(good: g) }
                        }
                    }
                    .padding(10)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .task {
            tag = initialTag
            await load()
        }
        .fullScreenCover(item: $detail) { g in
            GoodDetailPage(good: g, onClose: { detail = nil }, onCartChange: { Task { await loadCart() } })
        }
        .sheet(isPresented: $showCart) { CartPage(onClose: { showCart = false }) }
        .sheet(isPresented: $showOrders) { OrdersPage(onClose: { showOrders = false }) }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Button(action: onClose) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 38, height: 44)
            }
            HStack(spacing: 6) {
                SearchIcon(size: 15, color: Color(white: 0.6))
                TextField("", text: $keyword)
                    .placeholder(when: keyword.isEmpty) {
                        Text("搜索商品").foregroundColor(Color(white: 0.45))
                    }
                    .font(pf(14))
                    .foregroundColor(.white)
                    .onSubmit { Task { await load() } }
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color(white: 0.14)))

            Button { showOrders = true } label: {
                Text("订单").font(pf(13.5)).foregroundColor(.white)
            }
            Button { showCart = true } label: {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "cart.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    if cartCount > 0 {
                        Text(String(cartCount))
                            .font(pf(9.5, .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .frame(height: 14)
                            .background(Capsule().fill(Theme.primary))
                            .offset(x: 10, y: -6)
                    }
                }
                .frame(width: 34, height: 44)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 52)
    }

    private var tagBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(tags, id: \.self) { t in
                    Button {
                        tag = t
                        Task { await load() }
                    } label: {
                        Text(t)
                            .font(pf(13, tag == t ? .semibold : .regular))
                            .foregroundColor(tag == t ? .white : Color(white: 0.65))
                            .padding(.horizontal, 12)
                            .frame(height: 30)
                            .background(Capsule().fill(tag == t ? Theme.primary : Color(white: 0.14)))
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }

    private func load() async {
        var path = "/api/shop/goods"
        var parts: [String] = []
        if tag != "全部", let t = tag.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            parts.append("tag=" + t)
        }
        if !keyword.isEmpty, let k = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            parts.append("keyword=" + k)
        }
        if !parts.isEmpty { path += "?" + parts.joined(separator: "&") }
        if let r = try? await Api.get(path, as: Wrap.self) {
            goods = r.items ?? []
            if let t = r.tags, !t.isEmpty { tags = t }
        }
        await loadCart()
    }

    private func loadCart() async {
        if let c = try? await Api.get("/api/shop/cart", as: CartWrap.self) {
            cartCount = c.count ?? 0
        }
    }
}

struct GoodCard: View {
    let good: GoodRow

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topLeading) {
                cover
                    .frame(height: 170)
                    .clipped()
                if let tag = good.tag, !tag.isEmpty {
                    Text(tag)
                        .font(pf(10, .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .frame(height: 18)
                        .background(Capsule().fill(Theme.primary))
                        .padding(6)
                }
            }
            Text(good.title)
                .font(pf(13.5))
                .foregroundColor(.white)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            HStack(spacing: 4) {
                Text("¥")
                    .font(pf(11, .semibold))
                    .foregroundColor(Theme.primary)
                Text(priceText)
                    .font(pf(17, .semibold))
                    .foregroundColor(Theme.primary)
                Spacer()
                Text("已售 " + String(good.sold ?? 0))
                    .font(pf(10.5))
                    .foregroundColor(Color(white: 0.45))
            }
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.08)))
    }

    private var priceText: String {
        let p = good.price ?? 0
        return p == floor(p) ? String(Int(p)) : String(format: "%.1f", p)
    }

    @ViewBuilder
    private var cover: some View {
        if let p = good.poster, !p.isEmpty {
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
}

struct OrderRow: Codable, Identifiable {
    var id: String
    var total: Double?
    var status: String?
    var time: String?
    var items: [Item]?

    struct Item: Codable, Identifiable {
        var goodId: String
        var title: String
        var price: Double?
        var count: Int?
        var id: String { goodId }
    }
}

struct GoodDetailPage: View {
    let good: GoodRow
    var onClose: () -> Void
    var onCartChange: () -> Void
    @State private var count = 1
    @State private var toast = ""
    @State private var showCart = false

    struct Res: Codable { var ok: Bool?; var error: String? }
    struct OrderRes: Codable { var ok: Bool?; var order: OrderRow?; var error: String? }

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "商品详情", onBack: onClose, rightIcon: "cart", onRight: { showCart = true })
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    GoodCard(good: good)
                    info
                }
                .padding(14)
                .padding(.bottom, 90)
            }
            .overlay(alignment: .bottom) { bottomBar }
            .overlay(alignment: .bottom) { toastView }
        }
        .background(Color.black.ignoresSafeArea())
        .sheet(isPresented: $showCart) { CartPage(onClose: { showCart = false }) }
    }

    private var info: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(good.title).font(pf(18, .semibold)).foregroundColor(.white)
            Text(good.desc ?? "直播间同款，支持 7 天无理由退换。")
                .font(pf(13.5)).foregroundColor(Color(white: 0.6))
            HStack(spacing: 14) {
                Text("库存 " + String(good.stock ?? 0)).font(pf(12.5)).foregroundColor(Color(white: 0.5))
                Text("已售 " + String(good.sold ?? 0)).font(pf(12.5)).foregroundColor(Color(white: 0.5))
            }
            countRow
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.08)))
    }

    private var countRow: some View {
        HStack(spacing: 10) {
            Text("购买数量").font(pf(13.5)).foregroundColor(Color(white: 0.7))
            Spacer()
            Button { count = max(1, count - 1) } label: {
                Image(systemName: "minus").foregroundColor(.white)
                    .frame(width: 30, height: 28)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.15)))
            }
            Text(String(count)).font(pf(15, .medium)).foregroundColor(.white).frame(width: 30)
            Button { count = min(99, count + 1) } label: {
                Image(systemName: "plus").foregroundColor(.white)
                    .frame(width: 30, height: 28)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.15)))
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 10) {
            Button { addToCart() } label: {
                Text("加入购物车")
                    .font(pf(15, .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 46)
                    .background(RoundedRectangle(cornerRadius: 23).fill(Color(white: 0.2)))
            }
            Button { buyNow() } label: {
                Text("立即购买 ¥" + totalText)
                    .font(pf(15, .semibold)).foregroundColor(.white)
                    .frame(maxWidth: .infinity).frame(height: 46)
                    .background(RoundedRectangle(cornerRadius: 23).fill(Theme.primary))
            }
        }
        .padding(.horizontal, 14)
        .padding(.bottom, 14)
        .background(Color.black.opacity(0.9))
    }

    @ViewBuilder
    private var toastView: some View {
        if !toast.isEmpty {
            Text(toast)
                .font(pf(13)).foregroundColor(.white)
                .padding(.horizontal, 16).frame(height: 34)
                .background(Capsule().fill(Color.black.opacity(0.85)))
                .padding(.bottom, 80)
        }
    }

    private var totalText: String {
        let t = (good.price ?? 0) * Double(count)
        return t == floor(t) ? String(Int(t)) : String(format: "%.2f", t)
    }

    private func addToCart() {
        Task {
            _ = try? await Api.post("/api/shop/cart",
                                    body: ["goodId": good.id, "count": count], as: Res.self)
            toast = "已加入购物车"
            onCartChange()
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            toast = ""
        }
    }

    private func buyNow() {
        Task {
            let r = try? await Api.post("/api/shop/order",
                                        body: ["items": [["goodId": good.id, "count": count]]],
                                        as: OrderRes.self)
            toast = r?.ok == true ? "下单成功，去「订单」里看" : (r?.error ?? "下单失败")
            onCartChange()
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            toast = ""
        }
    }
}

struct CartPage: View {
    var onClose: () -> Void
    @State private var items: [CartItem] = []
    @State private var total: Double = 0
    @State private var toast = ""

    struct CartItem: Codable, Identifiable {
        var goodId: String
        var title: String
        var price: Double
        var poster: String?
        var count: Int
        var amount: Double
        var id: String { goodId }
    }
    struct Cart: Codable {
        var items: [CartItem]?
        var total: Double?
        var count: Int?
    }
    struct OrderRes: Codable { var ok: Bool?; var order: OrderRow?; var error: String? }

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "购物车", onBack: onClose, rightIcon: nil, onRight: nil)
            if items.isEmpty {
                Spacer()
                Text("购物车是空的").font(pf(14)).foregroundColor(Color(white: 0.5))
                Spacer()
            } else {
                list
                bottomBar
            }
        }
        .background(Color.black.ignoresSafeArea())
        .task { await load() }
        .overlay(alignment: .bottom) {
            if !toast.isEmpty {
                Text(toast).font(pf(13)).foregroundColor(.white)
                    .padding(.horizontal, 16).frame(height: 34)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .padding(.bottom, 90)
            }
        }
    }

    private var list: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(items) { it in
                    CartRow(item: it) { delta in
                        Task { await change(it, it.count + delta) }
                    }
                    Divider().background(Color(white: 0.12))
                }
            }
        }
    }

    private var bottomBar: some View {
        HStack {
            Text("合计").font(pf(14)).foregroundColor(Color(white: 0.7))
            Text("¥" + String(format: "%.2f", total))
                .font(pf(20, .semibold)).foregroundColor(Theme.primary)
            Spacer()
            Button { Task { await submit() } } label: {
                Text("结算")
                    .font(pf(15, .semibold)).foregroundColor(.white)
                    .padding(.horizontal, 22).frame(height: 42)
                    .background(Capsule().fill(Theme.primary))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(white: 0.06))
    }

    private func load() async {
        if let c = try? await Api.get("/api/shop/cart", as: Cart.self) {
            items = c.items ?? []
            total = c.total ?? 0
        }
    }

    private func change(_ it: CartItem, _ n: Int) async {
        _ = try? await Api.post("/api/shop/cart/count",
                                body: ["goodId": it.goodId, "count": max(0, n)], as: Cart.self)
        await load()
    }

    private func submit() async {
        let payload = items.map { ["goodId": $0.goodId, "count": $0.count] }
        let r = try? await Api.post("/api/shop/order", body: ["items": payload], as: OrderRes.self)
        if r?.ok == true {
            toast = "下单成功 ¥" + String(format: "%.2f", r?.order?.total ?? 0)
            await load()
        } else {
            toast = r?.error ?? "下单失败"
        }
        try? await Task.sleep(nanoseconds: 1_800_000_000)
        toast = ""
    }
}

struct CartRow: View {
    let item: CartPage.CartItem
    var onDelta: (Int) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(item.title).font(pf(14)).foregroundColor(.white).lineLimit(1)
            Spacer()
            Button { onDelta(-1) } label: {
                Image(systemName: "minus").font(.system(size: 12)).foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color(white: 0.15)))
            }
            Text(String(item.count)).font(pf(14)).foregroundColor(.white).frame(width: 24)
            Button { onDelta(1) } label: {
                Image(systemName: "plus").font(.system(size: 12)).foregroundColor(.white)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color(white: 0.15)))
            }
            Text("¥" + String(format: "%.2f", item.amount))
                .font(pf(14, .semibold))
                .foregroundColor(Theme.primary)
                .frame(width: 66, alignment: .trailing)
        }
        .padding(.horizontal, 14)
        .frame(height: 62)
    }
}

struct OrdersPage: View {
    var onClose: () -> Void
    @State private var orders: [OrderRow] = []
    struct Wrap: Codable { var items: [OrderRow]? }

    var body: some View {
        VStack(spacing: 0) {
            PageHeader(title: "我的订单", onBack: onClose, rightIcon: nil, onRight: nil)
            if orders.isEmpty {
                Spacer()
                Text("还没有订单").font(pf(14)).foregroundColor(Color(white: 0.5))
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(orders) { o in
                            OrderCard(order: o)
                        }
                    }
                    .padding(14)
                }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .task {
            if let r = try? await Api.get("/api/shop/orders", as: Wrap.self) {
                orders = r.items ?? []
            }
        }
    }
}

struct OrderCard: View {
    let order: OrderRow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("订单号 " + String(order.id.prefix(10)))
                    .font(pf(12)).foregroundColor(Color(white: 0.5))
                Spacer()
                Text(order.status ?? "")
                    .font(pf(12.5, .semibold))
                    .foregroundColor(statusColor)
            }
            ForEach(order.items ?? []) { it in
                itemRow(it)
            }
            HStack {
                Text(order.time ?? "").font(pf(11.5)).foregroundColor(Color(white: 0.45))
                Spacer()
                Text("合计 ¥" + String(format: "%.2f", order.total ?? 0))
                    .font(pf(15, .semibold)).foregroundColor(Theme.primary)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.08)))
    }

    private func itemRow(_ it: OrderRow.Item) -> some View {
        HStack {
            Text(it.title).font(pf(14)).foregroundColor(.white).lineLimit(1)
            Text("×" + String(it.count ?? 1)).font(pf(12.5)).foregroundColor(Color(white: 0.5))
            Spacer()
            Text("¥" + String(format: "%.2f", (it.price ?? 0) * Double(it.count ?? 1)))
                .font(pf(13)).foregroundColor(Color(white: 0.75))
        }
    }

    private var statusColor: Color {
        switch order.status {
        case "已完成": return Color(red: 0.2, green: 0.8, blue: 0.4)
        case "已取消": return Color(white: 0.5)
        case "已发货": return Color(red: 0.4, green: 0.7, blue: 1)
        default: return Theme.primary
        }
    }
}
