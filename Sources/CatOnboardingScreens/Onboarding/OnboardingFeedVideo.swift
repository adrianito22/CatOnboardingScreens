// OnboardingFeedVideo.swift
// CatScan — InteractiveOnboarding
//
// Looping, muted, controls-free video tile for the community-feed teaser.
// The clip is bundled in the asset catalog as a Data Set ("feed_curiosity_video")
// so it ships without any .pbxproj surgery; we materialise it to a temp file
// once (AVPlayer needs a URL) and loop it.

import SwiftUI
#if canImport(UIKit)
import UIKit
import AVFoundation
#endif

enum OnboardingFeedVideo {
    /// Resolves a bundled Data Set video to a temp-file URL (written once).
    /// Returns nil when the asset is missing or UIKit is unavailable.
    static func url(asset: String) -> URL? {
        #if canImport(UIKit)
        guard let data = NSDataAsset(name: asset)?.data else { return nil }
        let tmp = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(asset).mp4")
        if !FileManager.default.fileExists(atPath: tmp.path) {
            try? data.write(to: tmp)
        }
        return tmp
        #else
        _ = asset
        return nil
        #endif
    }
}

#if canImport(UIKit)

/// AVPlayerLayer-backed looping video, aspect-fill, muted, no controls.
final class LoopingVideoUIView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }
    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    private var queuePlayer: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    func configure(url: URL) {
        guard queuePlayer == nil else { return }
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer(playerItem: item)
        queue.isMuted = true
        queue.actionAtItemEnd = .advance
        looper = AVPlayerLooper(player: queue, templateItem: item)
        playerLayer.player = queue
        playerLayer.videoGravity = .resizeAspectFill
        queuePlayer = queue
        queue.play()
    }

    func play()  { queuePlayer?.play() }
    func pause() { queuePlayer?.pause() }
}

/// SwiftUI wrapper for the looping video tile.
struct LoopingVideoTile: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> LoopingVideoUIView {
        let v = LoopingVideoUIView()
        v.configure(url: url)
        return v
    }

    func updateUIView(_ uiView: LoopingVideoUIView, context: Context) {
        uiView.play()
    }
}

#endif
