//  FeedModel.swift
//  首页状态：拉后台数据、点赞收藏分享关注、评论、播放上报

import Foundation
import SwiftUI

enum FeedSheet: Identifiable {
    case comments, sameStyle, music, search, server
    var id: String {
        switch self {
        case .comments: return "comments"
        case .sameStyle: return "sameStyle"
        case .music: return "music"
        case .search: return "search"
        case .server: return "server"
        }
    }
}

@MainActor
final class FeedModel: ObservableObject {
    @Published var items: [Video] = Store.videos
    @Published var tabs: [String] = ["热点", "直播", "团购", "无锡", "关注", "商城", "推荐"]
    @Published var tabIndex: Int = 6
    @Published var unread: String = "65"
    @Published var online: Bool = false
    @Published var status: String = "本地演示数据"
    @Published var comments: [CommentItem] = []
    @Published var loadingComments = false
    @Published var sheet: FeedSheet?
    /// 界面参数变了要逼着界面重画，所以留一个计数器
    @Published var renderTick = 0

    private var nextCursor = 0
    private var hasMore = true
    private var loadedTabs: [RemoteTab] = []
    private var played = Set<String>()
    private var knownRev = 0
    private var pollTimer: Timer?
    // 行为上报（推荐算法靠这个学习）
    private var watchId = ""
    private var watchStart = Date()
    private var finished = Set<String>()
    private var eventSession = UUID().uuidString.prefix(8).lowercased()

    /// 开始看一条：曝光 + 开始播放
    func enterVideo(_ v: Video) {
        leaveVideo()
        guard online, !v.remoteId.isEmpty else { return }
        watchId = v.remoteId
        watchStart = Date()
        sendEvent("imp", v)
        sendEvent("play", v)
    }

    /// 划走：不到 3 秒算负反馈，否则算一次有效播放（带观看时长）
    func leaveVideo() {
        guard !watchId.isEmpty else { return }
        let ms = Int(Date().timeIntervalSince(watchStart) * 1000)
        let skipped = ms < 3000 && !finished.contains(watchId)
        sendEventRaw(skipped ? "skip" : "play", watchId, ["value": ms])
        watchId = ""
    }

    /// 看完（播放器回调）
    func markFinished(_ v: Video) {
        guard !v.remoteId.isEmpty, !finished.contains(v.remoteId) else { return }
        finished.insert(v.remoteId)
        sendEvent("finish", v)
    }

    /// 不感兴趣（author = true 表示不看他这个作者）
    func dislike(_ v: Video, author: Bool) {
        sendEvent("dislike", v, ["author": author])
        status = author ? "已减少这类作者的内容" : "已减少这类内容"
        let gone = v.remoteId
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            await bootstrap()          // 立刻重拉一版推荐
            if let idx = items.firstIndex(where: { $0.remoteId == gone }) { items.remove(at: idx) }
        }
    }

    private func sendEvent(_ type: String, _ v: Video, _ extra: [String: Any] = [:]) {
        guard !v.remoteId.isEmpty else { return }
        sendEventRaw(type, v.remoteId, extra)
    }

    private func sendEventRaw(_ type: String, _ videoId: String, _ extra: [String: Any] = [:]) {
        guard online else { return }
        var body: [String: Any] = ["type": type, "videoId": videoId,
                                   "viewer": ServerConfig.viewer,
                                   "session": String(eventSession)]
        extra.forEach { body[$0.key] = $0.value }
        Task {
            _ = try? await Api.post("/api/event", body: body, as: AlgoEventResult.self)
        }
    }

    func bootstrap() async {
        do {
            let r = try await Api.get("/api/bootstrap?count=5&viewer=\(ServerConfig.viewer)",
                                      as: BootstrapResponse.self)
            Theme.apply(r.settings)
            knownRev = r.rev ?? knownRev
            if let list = r.tabs, !list.isEmpty {
                loadedTabs = list
                tabs = list.map { $0.name }
                if let t = r.tab, let idx = list.firstIndex(where: { $0.id == t }) { tabIndex = idx }
            }
            // 注意：后台删空了也要跟着空，不然 App 会一直显示旧数据
            let list = r.items ?? []
            items = list.enumerated().map { Store.fromRemote($0.element, index: $0.offset) }
            nextCursor = r.nextCursor ?? items.count
            hasMore = r.hasMore ?? false
            unread = r.unread.map { $0 > 99 ? "99+" : String($0) } ?? Theme.unreadBadge
            online = true
            status = "已连接 · " + ServerConfig.base
            renderTick += 1
        } catch {
            online = false
            status = "连不上后台，先用本地演示数据"
            renderTick += 1
        }
    }

    /// 每 4 秒问一次后台版本号：后台改过东西就自动重拉（不用杀 App）
    func startPolling() {
        stopPolling()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: true) { [weak self] _ in
            Task { await self?.checkVersion() }
        }
    }

    func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    /// App 里手动关了/开了声音：写回后台，别的设备也跟着一致
    func setMutedFromApp(_ muted: Bool) {
        Task {
            _ = try? await Api.post("/api/settings/muted", body: ["muted": muted], as: MutedResult.self)
        }
    }

    func checkVersion() async {
        guard let v = try? await Api.get("/api/version", as: VersionResponse.self) else {
            if online { online = false; status = "与后台断开，稍后自动重连" }
            return
        }
        if let r = v.rev, r != knownRev {
            await bootstrap()
            return
        }
        if !online { await bootstrap() }
    }

    func selectTab(_ index: Int) async {
        tabIndex = index
        guard online, index < loadedTabs.count else { return }
        let tab = loadedTabs[index]
        do {
            let r = try await Api.get("/api/feed?tab=\(tab.id)&cursor=0&count=5&viewer=\(ServerConfig.viewer)",
                                      as: FeedResponse.self)
            if let list = r.items, !list.isEmpty {
                items = list.enumerated().map { Store.fromRemote($0.element, index: $0.offset) }
                nextCursor = r.nextCursor ?? items.count
                hasMore = r.hasMore ?? false
            } else {
                items = []
            }
            renderTick += 1
        } catch {
            status = "这一栏没拉到数据"
        }
    }

    func loadMoreIfNeeded(_ index: Int) {
        guard online, hasMore, index >= items.count - 2 else { return }
        let tab = tabIndex < loadedTabs.count ? loadedTabs[tabIndex].id : "recommend"
        let cursor = nextCursor
        Task {
            do {
                let r = try await Api.get("/api/feed?tab=\(tab)&cursor=\(cursor)&count=5&viewer=\(ServerConfig.viewer)",
                                          as: FeedResponse.self)
                let more = (r.items ?? []).enumerated().map {
                    Store.fromRemote($0.element, index: items.count + $0.offset)
                }
                if !more.isEmpty { items.append(contentsOf: more) }
                nextCursor = r.nextCursor ?? cursor
                hasMore = r.hasMore ?? false
            } catch {
                hasMore = false
            }
        }
    }

    func like(_ index: Int) async {
        guard items.indices.contains(index) else { return }
        let wasOn = items[index].liked
        items[index].liked = !wasOn
        let video = items[index]
        guard online, !video.remoteId.isEmpty else { return }
        do {
            let r = try await Api.post("/api/video/like?id=\(video.remoteId)&viewer=\(ServerConfig.viewer)",
                                       body: ["on": !wasOn], as: LikeResult.self)
            if let t = r.likeText { items[index].likes = t }
        } catch {
            items[index].liked = wasOn
        }
    }

    func favorite(_ index: Int) async {
        guard items.indices.contains(index) else { return }
        let wasOn = items[index].favorited
        items[index].favorited = !wasOn
        let video = items[index]
        guard online, !video.remoteId.isEmpty else { return }
        do {
            let r = try await Api.post("/api/video/favorite?id=\(video.remoteId)&viewer=\(ServerConfig.viewer)",
                                       body: ["on": !wasOn], as: LikeResult.self)
            if let t = r.favoriteText { items[index].favorites = t }
        } catch {
            items[index].favorited = wasOn
        }
    }

    func share(_ index: Int) async {
        guard items.indices.contains(index) else { return }
        let video = items[index]
        guard online, !video.remoteId.isEmpty else { return }
        if let r = try? await Api.post("/api/video/share?id=\(video.remoteId)&viewer=\(ServerConfig.viewer)",
                                       body: [:], as: LikeResult.self), let t = r.shareText {
            items[index].shares = t
        }
    }

    func follow(_ index: Int) async {
        guard items.indices.contains(index) else { return }
        let video = items[index]
        guard online, !video.authorId.isEmpty else { return }
        items[index].following = true
        _ = try? await Api.post("/api/user/follow?id=\(video.authorId)&viewer=\(ServerConfig.viewer)",
                                body: ["on": true], as: LikeResult.self)
    }

    func reportPlay(_ video: Video) {
        guard online, !video.remoteId.isEmpty, !played.contains(video.remoteId) else { return }
        played.insert(video.remoteId)
        let path = "/api/video/play?id=\(video.remoteId)&viewer=\(ServerConfig.viewer)"
        Task {
            _ = try? await Api.post(path, body: [:], as: LikeResult.self)
        }
    }

    func loadComments(_ video: Video) async {
        guard !video.remoteId.isEmpty else {
            comments = []
            return
        }
        loadingComments = true
        defer { loadingComments = false }
        do {
            let r = try await Api.get("/api/video/comments?id=\(video.remoteId)&viewer=\(ServerConfig.viewer)&count=50",
                                      as: CommentList.self)
            comments = r.items ?? []
        } catch {
            comments = []
            status = "评论没拉到"
        }
    }

    func postComment(_ video: Video, text: String) async {
        let body = text.trimmingCharacters(in: .whitespaces)
        guard !video.remoteId.isEmpty, !body.isEmpty else { return }
        _ = try? await Api.post("/api/video/comments?id=\(video.remoteId)&viewer=\(ServerConfig.viewer)",
                                body: ["text": body], as: OneComment.self)
        await loadComments(video)
        if let idx = items.firstIndex(where: { $0.remoteId == video.remoteId }) {
            if let n = Int(items[idx].comments) {
                items[idx].comments = String(n + 1)
            }
        }
    }
}
