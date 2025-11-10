//
//  PlayerVM.swift
//  RadioApp
//  Created by B.RF Group on 03.11.2025.
//
import Foundation

final class PlayerVM: ObservableObject {
    @Published var model: MusicM
    @Published var liked = true
    @Published var isPlaying = false
    @Published var index: Int
    @Published var stations: [MusicM]
    @Published var recentlyPlayed: [MusicM] = []
    
    init(model: MusicM, stations: [MusicM]) {
        self.stations = stations

        if stations.isEmpty {
            self.model = model
            self.index = 0
        } else {
            // determine index safely using a local variable to avoid using `self` before init completes
            let idx = stations.firstIndex(where: { $0.name == model.name && $0.streamUrl == model.streamUrl }) ?? 0
            self.model = stations[idx]
            self.index = idx
        }

        self.liked = RadioFetcher.shared.isFavorite(self.model)
    }
    
    func nextStation() {
        guard !stations.isEmpty else { return }
        index = (index + 1) % stations.count
        updateToCurrentIndex()
    }
    
    func prevStation() {
        guard !stations.isEmpty else { return }
        index = (index - 1 + stations.count) % stations.count
        updateToCurrentIndex()
    }
    
    private func updateToCurrentIndex() {
        model = stations[index]
        updateLiked()
        addToRecentlyPlayed(model)
    }
    
    func updateLiked() {
        liked = RadioFetcher.shared.isFavorite(model)
    }
    
    func toggleLiked() {
        if liked {
            RadioFetcher.shared.removeFromFavorites(model)
            liked = false
        } else {
            RadioFetcher.shared.addToFavorites(model)
            liked = true
        }
    }
    
    func addToRecentlyPlayed(_ station: MusicM) {
        if let existingIndex = recentlyPlayed.firstIndex(where: { $0.id == station.id }) {
            recentlyPlayed.remove(at: existingIndex)
        }
        recentlyPlayed.insert(station, at: 0)
        if recentlyPlayed.count > 10 {
            recentlyPlayed.removeLast()
        }
    }
}
