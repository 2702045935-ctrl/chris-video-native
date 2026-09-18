//  FeedView.swift
//  首页：全屏视频流（数据来自后台）+ 顶栏 + 右侧操作栏 + 左下文案 + 底栏

import SwiftUI

struct FeedScreen: View {
    @Binding var bottomTab: Int
    @StateObject var model = FeedModel()
    @State var index = 0
    @State var dragY: CGFloat = 0
    @State var burst = false
    @State var showSearch = false
    @State var showSameStyle = false
    @State var showMusic = false
    @State var showComments = false
    @State var showServer = false

    private var video: Video {
        model.items.indices.contains(index) ? model.items[index] : Store.videos[0]
    }

    var body: some View {
        ZStack {
            chrome.background(videoLayer)
            if burst {
                HeartShape()
                    .fill(Theme.primary)
                    .frame(width: 110, height: 100)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
        .task { await model.bootstrap() }
        .sheet(isPresented: $showSearch) { SearchPage(onClose: { showSearch = false }) }
        .sheet(isPresented: $showSameStyle) {
            SheetPage(title: "拍同款", onClose: { showSameStyle = false })
        }
        .sheet(isPresented: $showMusic) {
            SheetPage(title: video.musicTitle, subtitle: video.musicLine,
                      onClose: { showMusic = false })
        }
        .sheet(isPresented: $showComments) {
            CommentsSheet(model: model, video: video, isPresented: $showComments)
        }
        .sheet(isPresented: $showServer) {
            ServerSheet(model: model, isPresented: $showServer)
        }
    }

    // MARK: - 视频层

    private var videoLayer: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack {
                Color.black
                ForEach(model.items) { v in
                    VideoCanvas(video: v, isActive: v.id == model.items[safeIndex].id)
                        .frame(width: geo.size.width, height: h)
                        .offset(y: CGFloat(v.id - model.items[safeIndex].id) * h + dragY)
                }
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
                            next = min(index + 1, model.items.count - 1)
                        } else if dy > 60 || predicted > 200 {
                            next = max(index - 1, 0)
                        }
                        withAnimation(.interactiveSpring(response: 0.34, dampingFraction: 0.86)) {
                            index = next
                            dragY = 0
                        }
                        if next != index {
                            burst = false
                        }
                        model.reportPlay(video)
                        model.loadMoreIfNeeded(next)
                    }
            )
        }
        .ignoresSafeArea()
    }

    private var safeIndex: Int {
        model.items.isEmpty ? 0 : min(index, model.items.count - 1)
    }

    // MARK: - 上层 UI

    private var chrome: some View {
        ZStack {
            if Theme.showTopTabs {
                TopBar(tabs: model.tabs,
                       selected: $model.tabIndex,
                       onSelect: { i in
                           index = 0
                           Task { await model.selectTab(i) }
                       },
                       onSearch: { showSearch = true },
                       onMenu: { showServer = true })
            } else {
                GeometryReader { g in
                    SearchIcon(size: M.searchSize)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                        .onTapGesture { showSearch = true }
                        .position(x: g.size.width - M.searchCenterTrailing, y: M.topBarCenterBelowSafeTop)
                }
            }

            RailView(video: video,
                     onLike: { Task { await model.like(safeIndex) } },
                     onStar: { Task { await model.favorite(safeIndex) } },
                     onComment: {
                         showComments = true
                         Task { await model.loadComments(video) }
                     },
                     onShare: { Task { await model.share(safeIndex) } },
                     onFollow: { Task { await model.follow(safeIndex) } },
                     onSameStyle: { showSameStyle = true })

            CaptionView(video: video,
                        onRecommend: { },
                        onMusic: { showMusic = true })

            BottomBar(selected: $bottomTab, unread: model.unread, onPlus: { showSameStyle = true })
        }
    }

    private func like() {
        withAnimation(.easeOut(duration: 0.12)) { burst = true }
        Task { await model.like(safeIndex) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeIn(duration: 0.2)) { burst = false }
        }
    }
}
