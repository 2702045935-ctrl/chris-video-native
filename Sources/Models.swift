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
    let likes: String
    let comments: String
    let favorites: String
    let shares: String
    let musicLine: String
    let musicTitle: String
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
        Bundle.main.url(forResource: name, withExtension: "mp4")
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
                if let img = Store.image(video.poster) {
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
                    ClipPlayer(url: url, isActive: isActive, isMuted: true)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .onAppear {
                withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                    zoom = 1.07
                }
            }
        }
        .ignoresSafeArea()
    }
}
