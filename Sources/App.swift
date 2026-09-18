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
    @ObservedObject var auth = Auth.shared
    @State var showLogin = false

    var body: some View {
        ZStack {
            MainTabs(showLogin: $showLogin)
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
