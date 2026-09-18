//  PublishPages.swift
//  发布：从相册选视频 → 编辑（文案/话题/位置/权限/定时）→ 上传 → 出现在首页

import AVFoundation
import PhotosUI
import SwiftUI

struct PublishFlow: View {
    var onClose: () -> Void = { }
    @State private var pickerItem: PhotosPickerItem?
    @State private var videoData: Data?
    @State private var coverData: Data?
    @State private var title = ""
    @State private var topicText = ""
    @State private var city = "无锡"
    @State private var visibility = 0          // 0 公开 1 好友 2 私密
    @State private var scheduleAt: Date? = nil
    @State private var uploading = false
    @State private var progress = 0.0
    @State private var toast = ""
    @State private var done = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            header
            if videoData == nil {
                pickStep
            } else {
                editStep
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onChange(of: pickerItem) { item in
            guard let item = item else { return }
            Task { await loadPicked(item) }
        }
    }

    private var header: some View {
        HStack {
            Button {
                onClose()
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text(videoData == nil ? "发布" : "发布作品")
                .font(pf(16, .semibold))
                .foregroundColor(.white)
            Spacer()
            if videoData == nil {
                Color.clear.frame(width: 44, height: 44)
            } else {
                Button {
                    Task { await publish() }
                } label: {
                    Text(uploading ? "上传中" : "发布")
                        .font(pf(15, .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 14)
                        .frame(height: 32)
                        .background(Capsule().fill(uploading ? Color(white: 0.3) : Theme.primary))
                }
                .disabled(uploading)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 52)
    }

    private var pickStep: some View {
        VStack(spacing: 18) {
            Spacer()
            PhotosPicker(selection: $pickerItem, matching: .videos) {
                VStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(white: 0.14))
                            .frame(width: 120, height: 120)
                        Image(systemName: "plus")
                            .font(.system(size: 40, weight: .light))
                            .foregroundColor(.white)
                    }
                    Text("从相册选一个视频")
                        .font(pf(15, .medium))
                        .foregroundColor(.white)
                }
            }
            Text("选好后可以写文案、加话题、选位置、设置谁可以看")
                .font(pf(12.5))
                .foregroundColor(Color(white: 0.5))
            Spacer()
        }
    }

    private var editStep: some View {
        ScrollView {
            VStack(spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.15))
                            .frame(width: 92, height: 122)
                        if let d = coverData, let img = UIImage(data: d) {
                            Image(uiImage: img).resizable().aspectRatio(contentMode: .fill)
                                .frame(width: 92, height: 122)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        } else {
                            Image(systemName: "video.fill").foregroundColor(Color(white: 0.5))
                        }
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已选视频 " + sizeText(videoData?.count ?? 0))
                            .font(pf(13.5)).foregroundColor(.white)
                        Text("封面取的是第一帧").font(pf(12)).foregroundColor(Color(white: 0.5))
                        Button {
                            videoData = nil
                            coverData = nil
                            pickerItem = nil
                        } label: {
                            Text("重新选").font(pf(12.5)).foregroundColor(Theme.primary)
                        }
                    }
                    Spacer()
                }
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color(white: 0.08)))

                editor("作品描述", $title, "写点什么…", 4)
                editor("话题（用空格或逗号分开）", $topicText, "例如：生活 随手拍", 2)

                row("位置", city) {
                    city = city == "无锡" ? "苏州" : (city == "苏州" ? "上海" : "无锡")
                }
                row("谁可以看", ["公开", "好友", "私密"][visibility]) {
                    visibility = (visibility + 1) % 3
                }
                row("定时发布", scheduleAt == nil ? "立即" : "1 小时后") {
                    if scheduleAt == nil {
                        scheduleAt = Date().addingTimeInterval(3600)
                    } else {
                        scheduleAt = nil
                    }
                }

                if uploading {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("上传中 \(Int(progress * 100))%")
                            .font(pf(12.5)).foregroundColor(Color(white: 0.7))
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color(white: 0.15)).frame(height: 6)
                                Capsule().fill(Theme.primary)
                                    .frame(width: g.size.width * progress, height: 6)
                            }
                        }
                        .frame(height: 6)
                    }
                }
            }
            .padding(16)
        }
        .overlay(alignment: .bottom) {
            if !toast.isEmpty {
                Text(toast)
                    .font(pf(13))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(Capsule().fill(Color.black.opacity(0.8)))
                    .padding(.bottom, 30)
            }
        }
    }

    private func editor(_ label: String, _ text: Binding<String>, _ placeholder: String, _ lines: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label).font(pf(13)).foregroundColor(Color(white: 0.55))
            TextEditor(text: text)
                .font(pf(14.5))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .frame(height: CGFloat(lines) * 24 + 16)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.1)))
                .overlay(alignment: .topLeading) {
                    if text.wrappedValue.isEmpty {
                        Text(placeholder)
                            .font(pf(14.5))
                            .foregroundColor(Color(white: 0.4))
                            .padding(.horizontal, 13)
                            .padding(.vertical, 16)
                            .allowsHitTesting(false)
                    }
                }
        }
    }

    private func row(_ label: String, _ value: String, _ tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            HStack {
                Text(label).font(pf(14)).foregroundColor(.white)
                Spacer()
                Text(value).font(pf(13.5)).foregroundColor(Color(white: 0.6))
                Image(systemName: "chevron.right").font(.system(size: 12)).foregroundColor(Color(white: 0.4))
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.1)))
        }
    }

    private func sizeText(_ bytes: Int) -> String {
        if bytes > 1048576 { return String(format: "%.1f MB", Double(bytes) / 1048576) }
        return "\(bytes / 1024) KB"
    }

    /* MARK: - 动作 */

    private func loadPicked(_ item: PhotosPickerItem) async {
        uploading = true
        progress = 0.05
        if let data = try? await item.loadTransferable(type: Data.self) {
            videoData = data
            coverData = await firstFrame(of: data)
        }
        uploading = false
    }

    private func firstFrame(of data: Data) async -> Data? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("publish_tmp.mp4")
        try? data.write(to: url)
        let asset = AVURLAsset(url: url)
        let gen = AVAssetImageGenerator(asset: asset)
        gen.appliesPreferredTrackTransform = true
        if let cg = try? gen.copyCGImage(at: CMTime(seconds: 0.1, preferredTimescale: 600), actualTime: nil) {
            return UIImage(cgImage: cg).jpegData(compressionQuality: 0.8)
        }
        return nil
    }

    private func upload(_ data: Data, kind: String, name: String) async -> String? {
        guard let url = Api.url("/api/upload?kind=\(kind)&name=\(name)") else { return nil }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        if !ServerConfig.token.isEmpty { req.setValue(ServerConfig.token, forHTTPHeaderField: "X-Token") }
        req.setValue(ServerConfig.viewer, forHTTPHeaderField: "X-Viewer")
        struct Res: Codable { var url: String? }
        do {
            let (resp, _) = try await URLSession.shared.upload(for: req, from: data)
            let r = try JSONDecoder().decode(Res.self, from: resp)
            return r.url
        } catch {
            return nil
        }
    }

    private func publish() async {
        guard let data = videoData else { return }
        uploading = true
        toast = "上传中…"
        defer { uploading = false }

        let stamp = Int(Date().timeIntervalSince1970)
        guard let videoURL = await upload(data, kind: "videos", name: "app_\(stamp).mp4") else {
            toast = "上传失败，检查一下服务端"
            return
        }
        progress = 0.7
        var posterURL = ""
        if let cover = coverData, let p = await upload(cover, kind: "posters", name: "app_\(stamp).jpg") {
            posterURL = p
        }
        progress = 0.9

        struct Res: Codable { var ok: Bool?; var error: String? }
        let topics = topicText.split(whereSeparator: { $0 == " " || $0 == "," || $0 == "，" })
            .map { String($0) }.filter { !$0.isEmpty }
        let body: [String: Any] = [
            "title": title,
            "video": videoURL,
            "poster": posterURL,
            "topics": topics,
            "city": city,
            "visibility": visibility == 2 ? "private" : "public",
            "publishAt": scheduleAt.map { Int($0.timeIntervalSince1970 * 1000) } ?? 0
        ]
        _ = try? await Api.post("/api/publish", body: body, as: Res.self)
        progress = 1
        toast = scheduleAt == nil ? "发布成功，回首页就能看到" : "已设置定时发布"
        done = true
        try? await Task.sleep(nanoseconds: 900_000_000)
        onClose()
        dismiss()
    }
}
