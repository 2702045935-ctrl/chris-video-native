//  API.swift
//  连后台用的数据模型 / 网络 / 界面参数

import Foundation
import SwiftUI

enum ServerConfig {
    static let key = "chris_video_server"
    static let fallback = "http://192.168.2.7:5190"
    static let viewer = "u_me"

    static var base: String {
        get { UserDefaults.standard.string(forKey: key) ?? fallback }
        set {
            var v = newValue.trimmingCharacters(in: .whitespaces)
            if v.isEmpty { v = fallback }
            if !v.lowercased().hasPrefix("http") { v = "http://" + v }
            while v.hasSuffix("/") { v.removeLast() }
            UserDefaults.standard.set(v, forKey: key)
        }
    }
}

struct ServerSettings: Codable {
    var brandName: String?
    var primary: String?
    var likeColor: String?
    var starColor: String?
    var fontScale: Double?
    var railIconScale: Double?
    var tabFont: Double?
    var tabFontActive: Double?
    var authorFont: Double?
    var captionFont: Double?
    var musicFont: Double?
    var countFont: Double?
    var sameStyleFont: Double?
    var barFont: Double?
    var pillFont: Double?
    var showRecommend: Bool?
    var showMusic: Bool?
    var showTopTabs: Bool?
    var showFollow: Bool?
    var autoplay: Bool?
    var muted: Bool?
    var loop: Bool?
    var unreadBadge: String?
    var commentPlaceholder: String?
}

struct RemoteTab: Codable, Identifiable {
    var id: String
    var name: String
    var kind: String?
}

struct RemoteAuthor: Codable {
    var id: String
    var name: String
    var avatar: String?
    var fanText: String?
    var following: Bool?
}

struct RemoteMusic: Codable {
    var title: String?
    var author: String?
    var source: String?
}

struct RemoteTexts: Codable {
    var like: String?
    var comment: String?
    var favorite: String?
    var share: String?
}

struct RemoteVideo: Codable, Identifiable {
    var id: String
    var author: RemoteAuthor
    var title: String
    var music: RemoteMusic?
    var video: String?
    var poster: String?
    var texts: RemoteTexts?
    var recommendText: String?
    var liked: Bool?
    var favorited: Bool?
}

struct BootstrapResponse: Codable {
    var rev: Int?
    var settings: ServerSettings?
    var tabs: [RemoteTab]?
    var tab: String?
    var items: [RemoteVideo]?
    var nextCursor: Int?
    var hasMore: Bool?
    var unread: Int?
}

/// 后台数据版本：变了就说明后台改过东西
struct VersionResponse: Codable {
    var rev: Int?
    var videos: Int?
    var tabs: Int?
    var at: Int?
}

struct FeedResponse: Codable {
    var items: [RemoteVideo]?
    var nextCursor: Int?
    var hasMore: Bool?
    var total: Int?
}

struct CommentReply: Codable, Identifiable {
    var id: String
    var name: String
    var text: String
    var time: String?
    var like: Int?
}

struct CommentItem: Codable, Identifiable {
    var id: String
    var name: String
    var text: String
    var time: String?
    var like: Int?
    var replies: [CommentReply]?
}

struct CommentList: Codable {
    var items: [CommentItem]?
    var total: Int?
    var hasMore: Bool?
}

struct LikeResult: Codable {
    var on: Bool?
    var like: Int?
    var likeText: String?
    var favorite: Int?
    var favoriteText: String?
    var share: Int?
    var shareText: String?
    var play: Int?
    var following: Bool?
    var fanText: String?
}

struct OneComment: Codable {
    var comment: CommentItem?
}

enum ApiError: Error {
    case badURL
}

struct Api {
    static func url(_ path: String) -> URL? {
        URL(string: ServerConfig.base + path)
    }

    static func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        guard let u = url(path) else { throw ApiError.badURL }
        var req = URLRequest(url: u)
        req.timeoutInterval = 6
        req.setValue(ServerConfig.viewer, forHTTPHeaderField: "X-Viewer")
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(T.self, from: data)
    }

    static func post<T: Decodable>(_ path: String, body: [String: Any], as type: T.Type) async throws -> T {
        guard let u = url(path) else { throw ApiError.badURL }
        var req = URLRequest(url: u)
        req.httpMethod = "POST"
        req.timeoutInterval = 6
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(ServerConfig.viewer, forHTTPHeaderField: "X-Viewer")
        req.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
        let (data, _) = try await URLSession.shared.data(for: req)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - 界面参数（后台「账号设置 → App 界面参数」里改）

enum Theme {
    static var scale: CGFloat = 1
    static var railIconScale: CGFloat = 1
    static var tabFont: CGFloat = M.tabFontIdle
    static var tabFontActive: CGFloat = M.tabFontActive
    static var authorFont: CGFloat = M.authorFont
    static var captionFont: CGFloat = M.captionFont
    static var musicFont: CGFloat = M.musicFont
    static var countFont: CGFloat = M.railCountFont
    static var sameStyleFont: CGFloat = M.sameStyleFont
    static var barFont: CGFloat = M.bottomLabelFont
    static var pillFont: CGFloat = M.pillFont
    static var primary = Color(red: 0xFE / 255.0, green: 0x2C / 255.0, blue: 0x55 / 255.0)
    static var star = Color(red: 1, green: 0.78, blue: 0.086)
    static var showRecommend = true
    static var showMusic = true
    static var showTopTabs = true
    static var showFollow = true
    static var muted = true
    static var unreadBadge = "65"
    static var commentPlaceholder = "说点什么…"

    static func apply(_ s: ServerSettings?) {
        guard let s = s else { return }
        scale = CGFloat(s.fontScale ?? 1)
        railIconScale = CGFloat(s.railIconScale ?? 1)
        tabFont = CGFloat(s.tabFont ?? Double(M.tabFontIdle))
        tabFontActive = CGFloat(s.tabFontActive ?? Double(M.tabFontActive))
        authorFont = CGFloat(s.authorFont ?? Double(M.authorFont))
        captionFont = CGFloat(s.captionFont ?? Double(M.captionFont))
        musicFont = CGFloat(s.musicFont ?? Double(M.musicFont))
        countFont = CGFloat(s.countFont ?? Double(M.railCountFont))
        sameStyleFont = CGFloat(s.sameStyleFont ?? Double(M.sameStyleFont))
        barFont = CGFloat(s.barFont ?? Double(M.bottomLabelFont))
        pillFont = CGFloat(s.pillFont ?? Double(M.pillFont))
        if let hex = s.primary { primary = Color(hex: hex) ?? primary }
        if let hex = s.starColor { star = Color(hex: hex) ?? star }
        showRecommend = s.showRecommend ?? true
        showMusic = s.showMusic ?? true
        showTopTabs = s.showTopTabs ?? true
        showFollow = s.showFollow ?? true
        muted = s.muted ?? true
        unreadBadge = s.unreadBadge ?? "65"
        commentPlaceholder = s.commentPlaceholder ?? "说点什么…"
    }
}

extension Color {
    init?(hex: String) {
        var h = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if h.hasPrefix("#") { h.removeFirst() }
        if h.count == 3 {
            var out = ""
            for ch in h { out += "\(ch)\(ch)" }
            h = out
        }
        guard h.count == 6, let v = UInt32(h, radix: 16) else { return nil }
        self.init(red: Double((v >> 16) & 0xFF) / 255.0,
                  green: Double((v >> 8) & 0xFF) / 255.0,
                  blue: Double(v & 0xFF) / 255.0)
    }
}
