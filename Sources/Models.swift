//  Models.swift
//  视频数据 + 图片加载

import SwiftUI
import UIKit

struct Video: Identifiable {
    let id: Int
    let poster: String
    let clip: String
    let author: String
    let caption: String
    let recommend: String
    var likes: String
    var comments: String
    var favorites: String
    var shares: String
    let musicLine: String
    let musicTitle: String
    // 连上后台后才有
    var remoteId: String = ""
    var authorId: String = ""
    var avatar: String = ""
    var liked: Bool = false
    var favorited: Bool = false
    var following: Bool = false

    func with(liked: Bool? = nil, favorited: Bool? = nil, following: Bool? = nil) -> Video {
        var v = self
        if let x = liked { v.liked = x }
        if let x = favorited { v.favorited = x }
        if let x = following { v.following = x }
        return v
    }
}

enum Store {
    /// 首条视频完全照参考图，其余几条是同一套 UI 的占位内容
    static let videos: [Video] = [
        Video(id: 0, poster: "poster-01", clip: "clip-01",
              author: "@明澈",
              caption: "跟我一起喊、万能胶、胶万能",
              recommend: "共251人推荐",
              likes: "1.5万", comments: "1195", favorites: "2627", shares: "5138",
              musicLine: "去汽水听", musicTitle: "万人站站万人_白七白"),
        Video(id: 1, poster: "poster-02", clip: "clip-02",
              author: "@阿辰",
              caption: "这个角度真的绝了，随手一拍就是这样",
              recommend: "共1248人推荐",
              likes: "3.2万", comments: "806", favorites: "1.1万", shares: "2451",
              musicLine: "去汽水听", musicTitle: "夏天的风_橘子海"),
        Video(id: 2, poster: "poster-03", clip: "clip-03",
              author: "@小满",
              caption: "记录一下今天的晚霞",
              recommend: "共362人推荐",
              likes: "8621", comments: "233", favorites: "1904", shares: "655",
              musicLine: "去汽水听", musicTitle: "日落大道_孙楠"),
        Video(id: 3, poster: "poster-04", clip: "clip-04",
              author: "@大熊",
              caption: "三步搞定，真的很简单",
              recommend: "共96人推荐",
              likes: "4729", comments: "128", favorites: "736", shares: "302",
              musicLine: "去汽水听", musicTitle: "普通朋友_陶喆"),
        Video(id: 4, poster: "poster-05", clip: "clip-05",
              author: "@灵子",
              caption: "今晚的月亮好圆啊，拍给你们看",
              recommend: "共580人推荐",
              likes: "1.8万", comments: "912", favorites: "3204", shares: "1180",
              musicLine: "去汽水听", musicTitle: "月半小夜曲_李克勤"),
    ]

    static func image(_ name: String) -> UIImage? {
        for ext in ["jpg", "jpeg", "png", "heic"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext),
               let img = UIImage(contentsOfFile: url.path) {
                return img
            }
        }
        return UIImage(named: name)
    }

    /// 打包进 App 的短视频
    static func videoURL(_ name: String) -> URL? {
        if name.hasPrefix("http") { return URL(string: name) }
        return Bundle.main.url(forResource: name, withExtension: "mp4")
    }

    /// 后台返回的地址（posters/xx.jpg、videos/xx.mp4）拼成完整 URL
    static func media(_ path: String) -> String {
        if path.isEmpty || path.hasPrefix("http") { return path }
        return ServerConfig.base + "/uploads/" + path
    }

    /// 把后台的一条视频转成界面用的 Video
    static func fromRemote(_ r: RemoteVideo, index: Int) -> Video {
        Video(id: index,
              poster: r.poster.map { media($0) } ?? "",
              clip: r.video.map { media($0) } ?? "",
              author: r.author.name,
              caption: r.title,
              recommend: r.recommendText ?? "",
              likes: r.texts?.like ?? "0",
              comments: r.texts?.comment ?? "0",
              favorites: r.texts?.favorite ?? "0",
              shares: r.texts?.share ?? "0",
              musicLine: r.music?.source ?? "去汽水听",
              musicTitle: r.music?.title ?? "",
              remoteId: r.id,
              authorId: r.author.id,
              avatar: r.author.avatar.map { media($0) } ?? "",
              liked: r.liked ?? false,
              favorited: r.favorited ?? false,
              following: r.author.following ?? false)
    }
}

/// 全屏视频画面：真视频 + 封面垫底（视频没准备好时显示封面）
struct VideoCanvas: View {
    let video: Video
    let isActive: Bool
    @State var zoom: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                if video.poster.hasPrefix("http") {
                    AsyncImage(url: URL(string: video.poster)) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().aspectRatio(contentMode: .fill)
                        default:
                            Color(white: 0.08)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .scaleEffect(zoom)
                    .clipped()
                } else if let img = Store.image(video.poster) {
                    Image(uiImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .scaleEffect(zoom)
                        .clipped()
                } else {
                    LinearGradient(colors: [Color(white: 0.06), Color(white: 0.12)],
                                   startPoint: .top, endPoint: .bottom)
                }
                if let url = Store.videoURL(video.clip) {
                    ClipPlayer(url: url, isActive: isActive, isMuted: Theme.muted)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .onAppear {
                // 没有视频、只显示封面时才做缓慢推近；有视频就别白烧 GPU
                if Store.videoURL(video.clip) == nil {
                    withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                        zoom = 1.07
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

/// 离当前这条比较远的视频只画封面（不开播放器，滑动才不卡）
struct PosterOnly: View {
    let video: Video

    var body: some View {
        GeometryReader { geo in
            Group {
                if video.poster.hasPrefix("http") {
                    AsyncImage(url: URL(string: video.poster)) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().aspectRatio(contentMode: .fill)
                        default:
                            Color(white: 0.08)
                        }
                    }
                } else if let img = Store.image(video.poster) {
                    Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
                } else {
                    Color(white: 0.08)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
        }
        .ignoresSafeArea()
    }
}
