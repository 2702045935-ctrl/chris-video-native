//  FeedView.swift
//  首页：全屏视频 + 上下滑动切换 + 右侧操作栏 + 左下文案 + 顶栏 + 底栏

import SwiftUI

struct FeedScreen: View {
    @Binding var bottomTab: Int
    @State var index = 0
    @State var dragY: CGFloat = 0
    @State var liked: Set<Int> = []
    @State var starred: Set<Int> = []
    @State var burst = false
    @State var topTab = 6
    @State var showSearch = false
    @State var showSameStyle = false
    @State var showMusic = false
    @State var showMenu = false
    @State var showComments = false

    private var video: Video { Store.videos[index] }

    var body: some View {
        ZStack {
            // chrome 按安全区排布，视频层作为背景铺满整屏（含状态栏、Home 指示条下面）
            chrome.background(videoLayer)
            if burst {
                HeartShape()
                    .fill(C.red)
                    .frame(width: 110, height: 100)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $showSearch) { SearchPage(onClose: { showSearch = false }) }
        .sheet(isPresented: $showComments) {
            SheetPage(title: "\(video.comments) 条评论", subtitle: video.caption,
                      onClose: { showComments = false })
        }
        .sheet(isPresented: $showSameStyle) { SheetPage(title: "拍同款", onClose: { showSameStyle = false }) }
        .sheet(isPresented: $showMusic) {
            SheetPage(title: video.musicTitle, subtitle: video.musicLine, onClose: { showMusic = false })
        }
        .sheet(isPresented: $showMenu) { SheetPage(title: "菜单", onClose: { showMenu = false }) }
    }

    // MARK: - 视频层（铺满整屏，含状态栏和 Home 指示条下面）

    private var videoLayer: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack {
                Color.black
                ForEach(Store.videos) { v in
                    VideoCanvas(video: v, isActive: v.id == index)
                        .frame(width: geo.size.width, height: h)
                        .offset(y: CGFloat(v.id - index) * h + dragY)
                }
                // 上下一点点渐暗，保证白字清楚
                VStack(spacing: 0) {
                    LinearGradient(colors: [Color.black.opacity(0.22), Color.clear],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 120)
                    Spacer(minLength: 0)
                    LinearGradient(colors: [Color.clear, Color.black.opacity(0.30)],
                                   startPoint: .top, endPoint: .bottom)
                        .frame(height: 260)
                }
                .allowsHitTesting(false)
            }
            .frame(width: geo.size.width, height: h)
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture(count: 2) { like() }
            .gesture(
                DragGesture(minimumDistance: 14)
                    .onChanged { value in
                        dragY = value.translation.height
                    }
                    .onEnded { value in
                        let dy = value.translation.height
                        let predicted = value.predictedEndTranslation.height
                        var next = index
                        if dy < -60 || predicted < -200 {
                            next = min(index + 1, Store.videos.count - 1)
                        } else if dy > 60 || predicted > 200 {
                            next = max(index - 1, 0)
                        }
                        withAnimation(.interactiveSpring(response: 0.34, dampingFraction: 0.86)) {
                            index = next
                            dragY = 0
                        }
                    }
            )
        }
        .ignoresSafeArea()
    }

    // MARK: - 上层 UI

    private var chrome: some View {
        ZStack {
            TopBar(tabs: ["热点", "直播", "团购", "无锡", "关注", "商城", "推荐"],
                   selected: $topTab,
                   onSearch: { showSearch = true },
                   onMenu: { showMenu = true })

            RailView(video: video,
                     liked: Binding(get: { liked.contains(index) },
                                    set: { on in if on { liked.insert(index) } else { liked.remove(index) } }),
                     starred: Binding(get: { starred.contains(index) },
                                      set: { on in if on { starred.insert(index) } else { starred.remove(index) } }),
                     onComment: { showComments = true },
                     onShare: { },
                     onSameStyle: { showSameStyle = true })

            CaptionView(video: video,
                        onRecommend: { },
                        onMusic: { showMusic = true })

            BottomBar(selected: $bottomTab, unread: "65", onPlus: { showSameStyle = true })
        }
    }

    private func like() {
        liked.insert(index)
        withAnimation(.easeOut(duration: 0.12)) { burst = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeIn(duration: 0.2)) { burst = false }
        }
    }
}

/// 双击点赞时中间那个大红心
struct BurstHeart: View {
    var body: some View {
        HeartShape().fill(C.red).frame(width: 110, height: 100)
    }
}
