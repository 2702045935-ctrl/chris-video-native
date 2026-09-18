//  App.swift
//  入口

import SwiftUI
import AVFoundation

@main
struct ChrisVideoApp: App {
    init() {
        // 设成播放类：手机侧边的静音键拨下去也能出声（跟抖音一样）
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            // 失败就算了，至少别崩
        }
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

    var body: some View {
        ZStack {
            if bottomTab == 0 {
                FeedScreen(bottomTab: $bottomTab)
            } else {
                TabPage(index: bottomTab, selected: $bottomTab)
            }
        }
        .background(Color.black.ignoresSafeArea())
    }
}
