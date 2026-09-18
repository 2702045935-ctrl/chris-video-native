//  ClipPlayer.swift
//  用 AVPlayerLayer 播本地短视频（循环、静音），没准备好时先显示封面图

import AVFoundation
import SwiftUI
import UIKit

/// 音频会话：设成「播放」类，手机侧边静音键拨下去也照样出声（抖音就是这么做的）
enum Audio {
    static func activate() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .moviePlayback, options: [])
            try session.setActive(true)
        } catch {
            // 失败不影响界面，最多是静音键拨下去没声
        }
    }
}

struct ClipPlayer: UIViewRepresentable {
    let url: URL
    let isActive: Bool
    let isMuted: Bool

    func makeUIView(context: Context) -> PlayerContainerView {
        let view = PlayerContainerView()
        view.load(url: url, muted: isMuted)
        view.setActive(isActive)
        return view
    }

    func updateUIView(_ view: PlayerContainerView, context: Context) {
        view.setMuted(isMuted)
        view.setActive(isActive)
    }

    static func dismantleUIView(_ view: PlayerContainerView, coordinator: ()) {
        view.shutdown()
    }
}

final class PlayerContainerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var player: AVPlayer?
    private var statusObs: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    private var wantsPlay = false

    private var playerLayer: AVPlayerLayer? { layer as? AVPlayerLayer }

    func load(url: URL, muted: Bool) {
        Audio.activate()
        let item = AVPlayerItem(url: url)
        let p = AVPlayer(playerItem: item)
        p.isMuted = muted
        p.volume = 1
        p.actionAtItemEnd = .none
        player = p
        playerLayer?.videoGravity = .resizeAspectFill
        backgroundColor = .clear

        // 等真正能播了再挂上去，避免第一帧黑一下
        statusObs = item.observe(\.status, options: [.initial, .new]) { [weak self] it, _ in
            guard let self = self else { return }
            if it.status == .readyToPlay {
                self.playerLayer?.player = self.player
                if self.wantsPlay { self.player?.play() }
            }
        }

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak p] _ in
            p?.seek(to: .zero)
            p?.play()
        }
    }

    func setActive(_ active: Bool) {
        wantsPlay = active
        guard let p = player else { return }
        if active {
            p.play()
        } else {
            p.pause()
            p.seek(to: .zero)
        }
    }

    /// 后台「静音」开关改了，立刻生效（不用重进 App）
    func setMuted(_ muted: Bool) {
        player?.isMuted = muted
    }

    func shutdown() {
        player?.pause()
        statusObs?.invalidate()
        statusObs = nil
        if let o = endObserver {
            NotificationCenter.default.removeObserver(o)
            endObserver = nil
        }
        playerLayer?.player = nil
        player = nil
    }
}
