//
//  RadioPlayer.swift
//  MusicApp
//  Created by B.RF Group on 03.11.2025.
//
import AVKit
import Foundation
import MediaPlayer

final class RadioPlayer: ObservableObject {
    var player = AVPlayer()
    
    @Published var isPlaying = false
    @Published var efir: MusicM? = nil
    @Published var volume: Double = 1.0 {
        didSet {
            player.volume = Float(volume)
        }
    }
    @Published var isBuffering = false
    
    @Published var currentIndex: Int? = nil
    var stations: [MusicM] = []
    
    private let recentlyPlayedNotification = Notification.Name("RadioPlayerRecentlyPlayed")
    
    init(stations: [MusicM] = []) {
        self.stations = stations
        setupAudioSession()
        setupRemoteCommandCenter()
    }
    
    // MARK: - Audio Session Setup
    
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    // MARK: - Remote Command Center (Lock Screen Controls)
    
    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            guard let self = self, let efir = self.efir else { return .noSuchContent }
            self.play(efir)
            return .success
        }
        
        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.stop()
            return .success
        }
        
        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextStation()
            return .success
        }
        
        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.prevStation()
            return .success
        }
    }
    
    // MARK: - Now Playing Info
    
    private func updateNowPlayingInfo() {
        guard let efir = efir else { return }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = efir.name
        nowPlayingInfo[MPMediaItemPropertyArtist] = "Radio Station"
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = true
        
        // Try to load artwork
        if let imageUrl = URL(string: efir.imageUrl.absoluteString) {
            URLSession.shared.dataTask(with: imageUrl) { data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    nowPlayingInfo[MPMediaItemPropertyArtwork] = artwork
                    DispatchQueue.main.async {
                        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
                    }
                }
            }.resume()
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    func initPlayer(url: String) {
        guard let url = URL(string: url) else { return }
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        player.volume = Float(volume)
    }

    func play(_ efir: MusicM) {
        self.efir = efir
        if let index = stations.firstIndex(where: { $0.id == efir.id }) {
            currentIndex = index
        } else {
            currentIndex = nil
        }

        isBuffering = true
        initPlayer(url: efir.streamUrl)
        player.volume = Float(volume)
        player.play()
        isPlaying = true
        
        // Update buffering state after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.isBuffering = false
        }
        
        // Update Now Playing Info for Lock Screen
        updateNowPlayingInfo()

        // Notify about recently played station
        NotificationCenter.default.post(name: recentlyPlayedNotification, object: efir)
    }
    
    func stop() {
        isPlaying = false
        player.pause()
    }
    
    func nextStation() {
        guard !stations.isEmpty else { return }
        
        if let currentIndex = currentIndex {
            let nextIndex = (currentIndex + 1) % stations.count
            let nextStation = stations[nextIndex]
            play(nextStation)
        } else {
            play(stations[0])
        }
    }
    
    func prevStation() {
        guard !stations.isEmpty else { return }
        
        if let currentIndex = currentIndex {
            let prevIndex = (currentIndex - 1 + stations.count) % stations.count
            let prevStation = stations[prevIndex]
            play(prevStation)
        } else {
            play(stations[0])
        }
    }
}
