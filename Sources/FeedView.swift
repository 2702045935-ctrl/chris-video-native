//  FeedView.swift
//  首页：全屏视频流（数据来自后台）+ 顶栏 + 右侧操作栏 + 左下文案 + 底栏

import SwiftUI

struct FeedScreen: View {
    @Binding var bottomTab: Int
    @Binding var showLogin: Bool
    @StateObject var model = FeedModel()
    @Environment(\.scenePhase) private var scenePhase
    @State var index = 0
    @State var dragY: CGFloat = 0
    @State var burst = false
    @State var showSearch = false
    @State var showSameStyle = false
    @State var showMusic = false
    @State var showComments = false
    @State var showServer = false
    @State var showDislike = false

    private var video: Video {
        model.items.indices.contains(index) ? model.items[index] : Store.videos[0]
    }

    var body: some View {
        ZStack {
            if model.items.isEmpty {
                emptyState
            } else {
                chrome.background(videoLayer)
            }
            if burst {
                HeartShape()
                    .fill(Theme.primary)
                    .frame(width: 110, height: 100)
                    .transition(.scale(scale: 0.3).combined(with: .opacity))
            }
        }
        .overlay(alignment: .top) {
            if !model.items.isEmpty && !model.online {
                offlineBanner
            }
        }
        .task {
            await model.bootstrap()
            model.enterVideo(video)
            model.startPolling()
        }
        .onChange(of: scenePhase) { phase in
            if phase == .active {
                Audio.activate()          // 回到前台重新占上音频会话，保证还有声
                Task { await model.bootstrap() }
            } else {
                model.stopPolling()
            }
        }
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
        .confirmationDialog("这条视频", isPresented: $showDislike, titleVisibility: .visible) {
            Button("不感兴趣") {
                model.dislike(video, author: false)
            }
            Button("不感兴趣 · " + video.author, role: .destructive) {
                model.dislike(video, author: true)
            }
            Button("取消", role: .cancel) { }
        } message: {
            Text("告诉算法少推这类内容")
        }
    }

    /// 后台一条作品都没有时（比如刚删空 / 还没发布）
    private var emptyState: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            VStack(spacing: 14) {
                Text("这一栏还没有作品")
                    .font(pf(17, .semibold))
                    .foregroundColor(.white)
                Text(model.online
                     ? "去后台「作品发布」传一条，这边不用重启就会自己出现"
                     : "现在连不上后台，先用本地演示数据兜底")
                    .font(pf(13.5))
                    .foregroundColor(Color(white: 0.62))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                Text(ServerConfig.base)
                    .font(pf(12.5))
                    .foregroundColor(Color(white: 0.45))
                HStack(spacing: 10) {
                    Button {
                        Task { await model.bootstrap() }
                    } label: {
                        Text("重新连接")
                            .font(pf(14, .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .frame(height: 38)
                            .background(Capsule().fill(Theme.primary))
                    }
                    Button {
                        showServer = true
                    } label: {
                        Text("改服务器地址")
                            .font(pf(14))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 38)
                            .background(Capsule().fill(Color(white: 0.18)))
                    }
                }
                .padding(.top, 4)
            }
        }
        .ignoresSafeArea()
    }

    private var offlineBanner: some View {
        Button {
            showServer = true
        } label: {
            HStack(spacing: 6) {
                Circle().fill(Color.orange).frame(width: 7, height: 7)
                Text("未连上后台 · " + ServerConfig.base)
                    .font(pf(12))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .frame(height: 30)
            .background(Capsule().fill(Color.black.opacity(0.55)))
        }
        .padding(.top, 4)
    }

    // MARK: - 视频层

    private var videoLayer: some View {
        GeometryReader { geo in
            let h = geo.size.height
            ZStack {
                Color.black
                ForEach(model.items) { v in
                    // 只给「当前这条 + 前后各一条」真开播放器，其他只画封面 —— 一屏 5 个播放器会卡
                    Group {
                        if abs(v.id - model.items[safeIndex].id) <= 1 {
                            VideoCanvas(video: v, isActive: v.id == model.items[safeIndex].id,
                                        onFinished: { model.markFinished(v) })
                        } else {
                            PosterOnly(video: v)
                        }
                    }
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
                        // 行为上报：曝光 + 有效播放/划走
                        model.enterVideo(video)
                    }
            )
            .onLongPressGesture(minimumDuration: 0.5) { showDislike = true }
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
                     onLike: {
                         guard requireLogin() else { return }
                         Task { await model.like(safeIndex) }
                     },
                     onStar: {
                         guard requireLogin() else { return }
                         Task { await model.favorite(safeIndex) }
                     },
                     onComment: {
                         guard requireLogin() else { return }
                         showComments = true
                         Task { await model.loadComments(video) }
                     },
                     onShare: {
                         guard requireLogin() else { return }
                         Task { await model.share(safeIndex) }
                     },
                     onFollow: {
                         guard requireLogin() else { return }
                         Task { await model.follow(safeIndex) }
                     },
                     onSameStyle: { showSameStyle = true })

            CaptionView(video: video,
                        onRecommend: { },
                        onMusic: { showMusic = true })

            BottomBar(selected: $bottomTab, unread: model.unread, onPlus: { showSameStyle = true })
        }
        // 后台改了字号/颜色，用 renderTick 逼着整套界面重画
        .id(model.renderTick)
    }

    private func like() {
        guard requireLogin() else { return }
        withAnimation(.easeOut(duration: 0.12)) { burst = true }
        Task { await model.like(safeIndex) }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeIn(duration: 0.2)) { burst = false }
        }
    }

    /// 游客模式下点赞/评论/关注先要求登录（跟抖音一样：不登录能刷，互动要登录）
    private func requireLogin() -> Bool {
        if Auth.shared.isLoggedIn { return true }
        Auth.shared.lastError = ""
        showLogin = true
        return false
    }
}
