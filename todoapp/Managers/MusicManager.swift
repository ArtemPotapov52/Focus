import MediaPlayer
import SwiftUI
import AVFoundation
import UIKit

@Observable
final class MusicManager {
    var title: String?
    var artist: String?
    var artwork: Image?
    var isPlaying = false
    var hasContent = false
    var currentTime: TimeInterval = 0
    var duration: TimeInterval = 0

    private var timer: Timer?

    var progress: Double {
        duration > 0 ? currentTime / duration : 0
    }

    var currentTimeString: String {
        timeString(currentTime)
    }

    var durationString: String {
        timeString(duration)
    }

    init() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: .mixWithOthers)
        try? session.setActive(true)
        refresh()
        NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: session, queue: .main) { [weak self] _ in
            self?.refresh()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            self?.refresh()
        }
        startTimer()
    }

    func refresh() {
        let info = readNowPlaying()

        title = info?[MPMediaItemPropertyTitle] as? String
        artist = info?[MPMediaItemPropertyArtist] as? String
        duration = info?[MPMediaItemPropertyPlaybackDuration] as? TimeInterval ?? 0
        currentTime = info?[MPNowPlayingInfoPropertyElapsedPlaybackTime] as? TimeInterval ?? currentTime

        if let artData = info?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork,
           let img = artData.image(at: CGSize(width: 60, height: 60))
        {
            artwork = Image(uiImage: img)
        } else {
            artwork = nil
        }

        let audioPlaying = AVAudioSession.sharedInstance().isOtherAudioPlaying
        isPlaying = audioPlaying
        hasContent = title != nil || artist != nil || audioPlaying
    }

    private func readNowPlaying() -> [String: Any]? {
        if let info = MPNowPlayingInfoCenter.default().nowPlayingInfo, !info.isEmpty {
            return info
        }
        let player = MPMusicPlayerController.systemMusicPlayer
        if let item = player.nowPlayingItem {
            var dict: [String: Any] = [:]
            dict[MPMediaItemPropertyTitle] = item.title
            dict[MPMediaItemPropertyArtist] = item.artist
            dict[MPMediaItemPropertyPlaybackDuration] = item.playbackDuration
            if let art = item.artwork {
                dict[MPMediaItemPropertyArtwork] = art
            }
            return dict
        }
        return nil
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            guard let self else { return }
            refresh()
            if isPlaying { currentTime += 1 }
        }
    }

    private func timeString(_ t: TimeInterval) -> String {
        guard !t.isNaN, !t.isInfinite else { return "0:00" }
        let m = Int(t) / 60
        let s = Int(t) % 60
        return "\(m):\(String(format: "%02d", s))"
    }
}
