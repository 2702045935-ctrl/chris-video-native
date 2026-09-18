//  MainTabs.swift
//  抖音那套底部 5 个 tab：首页 / 朋友 / ＋ / 消息 / 我

import SwiftUI

enum MainTab: Int, CaseIterable {
    case home = 0, friends, publish, messages, me

    var title: String {
        switch self {
        case .home: return "首页"
        case .friends: return "朋友"
        case .publish: return ""
        case .messages: return "消息"
        case .me: return "我"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .friends: return "person.2.fill"
        case .publish: return "plus"
        case .messages: return "ellipsis.message.fill"
        case .me: return "person.fill"
        }
    }
}

struct MainTabs: View {
    @Binding var showLogin: Bool
    @ObservedObject var auth = Auth.shared
    @State private var tab: MainTab = .home
    @State private var showPublish = false
    @State private var showSearch = false
    @State private var unread = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:
                    FeedScreen(bottomTab: .constant(0), showLogin: $showLogin, onOpenSearch: { showSearch = true })
                case .friends:
                    FriendsPage(onOpenSearch: { showSearch = true })
                case .messages:
                    MessagesPage()
                case .me:
                    MePage(showLogin: $showLogin)
                case .publish:
                    Color.black
                }
            }
            .ignoresSafeArea(edges: .bottom)

            BottomTabBar(tab: $tab, unread: unread) {
                showPublish = true
            }
        }
        .fullScreenCover(isPresented: $showPublish) {
            PublishFlow()
        }
        .fullScreenCover(isPresented: $showSearch) {
            SearchPage2(onClose: { showSearch = false })
        }
        .task {
            await refreshUnread()
        }
        .onChange(of: tab) { _ in Task { await refreshUnread() } }
    }

    private func refreshUnread() async {
        struct Summary: Codable { var unread: Int? }
        if let s = try? await Api.get("/api/messages/summary", as: Summary.self) {
            unread = s.unread ?? 0
        }
    }
}

/// 底部栏：首页 朋友 ＋ 消息 我
struct BottomTabBar: View {
    @Binding var tab: MainTab
    var unread: Int
    var onPlus: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            item(.home)
            item(.friends)
            Button(action: onPlus) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .fill(Color.white)
                    PlusIcon(size: 13, thickness: 2.6, color: .black)
                }
                .frame(width: 40, height: 28)
            }
            .frame(maxWidth: .infinity)
            item(.messages)
            item(.me)
        }
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(
            ZStack {
                Color.black.opacity(0.92)
                LinearGradient(colors: [Color.clear, Color.black.opacity(0.5)],
                               startPoint: .top, endPoint: .bottom)
                    .frame(height: 30)
                    .offset(y: -30)
            }
            .ignoresSafeArea(edges: .bottom)
        )
    }

    private func item(_ t: MainTab) -> some View {
        Button {
            tab = t
        } label: {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: t.icon)
                        .font(.system(size: 20, weight: tab == t ? .semibold : .regular))
                        .foregroundColor(tab == t ? .white : Color(white: 0.55))
                    if t == .messages && unread > 0 {
                        Text(unread > 99 ? "99+" : String(unread))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .frame(height: 14)
                            .background(Capsule().fill(Theme.primary))
                            .offset(x: 12, y: -6)
                    }
                }
                Text(t.title)
                    .font(.system(size: 10.5, weight: tab == t ? .semibold : .regular))
                    .foregroundColor(tab == t ? .white : Color(white: 0.55))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
    }
}

/// 其他页面统一用的顶部栏（返回 + 标题 + 右侧按钮）
struct PageHeader: View {
    var title: String
    var onBack: (() -> Void)?
    var rightIcon: String?
    var onRight: (() -> Void)?

    var body: some View {
        HStack(spacing: 12) {
            if let onBack = onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 40, height: 44)
                }
            }
            Text(title)
                .font(pf(16.5, .semibold))
                .foregroundColor(.white)
            Spacer()
            if let icon = rightIcon, let onRight = onRight {
                Button(action: onRight) {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(Color(white: 0.8))
                        .frame(width: 40, height: 44)
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 48)
        .background(Color.black)
    }
}
