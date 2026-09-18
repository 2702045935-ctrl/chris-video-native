//  App.swift
//  入口

import SwiftUI
import AVFoundation

@main
struct ChrisVideoApp: App {
    init() {
        Audio.activate()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
                .statusBarHidden(false)
        }
    }
}

struct RootView: View {
    @State var bottomTab = 0
    @ObservedObject var auth = Auth.shared
    @State var showLogin = false

    var body: some View {
        ZStack {
            if bottomTab == 0 {
                FeedScreen(bottomTab: $bottomTab, showLogin: $showLogin)
            } else {
                TabPage(index: bottomTab, selected: $bottomTab)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .fullScreenCover(isPresented: $showLogin) {
            LoginView(finished: $showLogin)
        }
        .task {
            await auth.loadConfig()
            await auth.restore()
            // 没登录也不是游客模式 → 先走抖音那套登录（右上角可以跳过）
            if !auth.isLoggedIn && !auth.guest { showLogin = true }
        }
    }
}
