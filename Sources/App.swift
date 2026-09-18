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
