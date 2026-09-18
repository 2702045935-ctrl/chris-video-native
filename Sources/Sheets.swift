//  Sheets.swift
//  评论面板 + 服务器地址面板

import SwiftUI

struct CommentsSheet: View {
    @ObservedObject var model: FeedModel
    let video: Video
    @Binding var isPresented: Bool
    @State var text = ""

    var body: some View {
        ZStack {
            Color(white: 0.09).ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Text(video.comments + " 条评论")
                        .font(pf(15, .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Text("关闭").font(pf(14)).foregroundColor(Color(white: 0.6))
                    }
                }
                .padding(.horizontal, 16)
                .frame(height: 52)

                Divider().background(Color(white: 0.2))

                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        if model.loadingComments && model.comments.isEmpty {
                            Text("加载中…")
                                .font(pf(13))
                                .foregroundColor(Color(white: 0.5))
                                .padding(20)
                        } else if model.comments.isEmpty {
                            Text(model.online ? "还没有评论，来说第一句" : "连上后台才有评论")
                                .font(pf(13))
                                .foregroundColor(Color(white: 0.5))
                                .padding(20)
                        }
                        ForEach(model.comments) { c in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Color(white: 0.25))
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text(String(c.name.prefix(1)))
                                                .font(pf(13, .semibold))
                                                .foregroundColor(.white)
                                        )
                                    Text(c.name)
                                        .font(pf(13))
                                        .foregroundColor(Color(white: 0.62))
                                    Spacer()
                                }
                                Text(c.text)
                                    .font(pf(14))
                                    .foregroundColor(.white)
                                HStack(spacing: 12) {
                                    Text(c.time ?? "")
                                        .font(pf(12))
                                        .foregroundColor(Color(white: 0.45))
                                    Text("赞 " + String(c.like ?? 0))
                                        .font(pf(12))
                                        .foregroundColor(Color(white: 0.45))
                                }
                                if let replies = c.replies {
                                    ForEach(replies) { r in
                                        HStack(alignment: .top, spacing: 6) {
                                            Text(r.name)
                                                .font(pf(12.5, .semibold))
                                                .foregroundColor(Color(white: 0.7))
                                            Text(r.text)
                                                .font(pf(12.5))
                                                .foregroundColor(Color(white: 0.85))
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            Divider().background(Color(white: 0.16))
                        }
                    }
                }

                HStack(spacing: 10) {
                    TextField("", text: $text)
                        .placeholder(when: text.isEmpty) {
                            Text(Theme.commentPlaceholder).foregroundColor(Color(white: 0.45))
                        }
                        .font(pf(14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .frame(height: 38)
                        .background(RoundedRectangle(cornerRadius: 19).fill(Color(white: 0.16)))
                    Button {
                        let body = text
                        text = ""
                        Task { await model.postComment(video, text: body) }
                    } label: {
                        Text("发送")
                            .font(pf(14, .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .frame(height: 38)
                            .background(Capsule().fill(Theme.primary))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 18)
            }
        }
        .preferredColorScheme(.dark)
        .task { await model.loadComments(video) }
    }
}

struct ServerSheet: View {
    @ObservedObject var model: FeedModel
    @Binding var isPresented: Bool
    @State var addr = ServerConfig.base
    @State var result = ""
    @State var busy = false

    var body: some View {
        ZStack {
            Color(white: 0.09).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("连接后台")
                        .font(pf(17, .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Text("关闭").font(pf(14)).foregroundColor(Color(white: 0.6))
                    }
                }
                Text("填电脑上跑的「CHRIS视频 服务端」地址，手机和电脑要连同一个 Wi-Fi。")
                    .font(pf(13))
                    .foregroundColor(Color(white: 0.6))
                TextField("", text: $addr)
                    .placeholder(when: addr.isEmpty) { Text("http://192.168.2.7:5190") }
                    .font(pf(14))
                    .foregroundColor(.white)
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding(.horizontal, 12)
                    .frame(height: 40)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.16)))
                Button {
                    busy = true
                    ServerConfig.base = addr
                    Task {
                        await model.bootstrap()
                        result = model.status
                        busy = false
                    }
                } label: {
                    Text(busy ? "连接中…" : "保存并连接")
                        .font(pf(15, .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(RoundedRectangle(cornerRadius: 22).fill(Theme.primary))
                }
                Text(result.isEmpty ? model.status : result)
                    .font(pf(12.5))
                    .foregroundColor(model.online ? Color(red: 0.2, green: 0.8, blue: 0.4) : Color(white: 0.55))
                Spacer()
            }
            .padding(20)
        }
        .preferredColorScheme(.dark)
    }
}
