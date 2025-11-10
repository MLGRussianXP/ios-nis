//
//  HomeVM.swift
//  RadioApp
//  Created by B.RF Group on 03.11.2025.
//
import Foundation
import SwiftUI
import Combine

public class RadioFetcher: ObservableObject {
    static let shared = RadioFetcher()
    
    @Published var isLoading = true
    @Published var efirs = [MusicM]()
    @Published var favEfirs = [MusicM]()
    @Published var recentlyPlayed: [MusicM] = []
    
    let favouritesKey = "favourites"
    
    init() {
        load()
    }
    
    private func load() {
        isLoading = true
        guard let url = URL(string: "https://de1.api.radio-browser.info/json/stations/bycodec/aac?limit=60&order=clicktrend&hidebroken=true") else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            do {
                if let data = data {
                    let decodedLists = try JSONDecoder().decode([MusicM].self, from: data)
                    DispatchQueue.main.async {
                        self.efirs = decodedLists.filter { 
                            !$0.name.isEmpty && 
                            !$0.streamUrl.isEmpty &&
                            $0.imageUrl.absoluteString != "https://i.postimg.cc/dVhrFLff/temp-Image-Ox-S6ie.avif" 
                        }
                        self.isLoading = false
                        _ = self.getFavourites()
                    }
                } else {
                    print("No data received from server")
                    DispatchQueue.main.async {
                        self.isLoading = false
                    }
                }
            } catch {
                print("Failed to decode stations: \(error)")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
    
    // Сохранение массива названий избранных станций в UserDefaults
    func saveFavourites(_ favEfirs: [MusicM]) { // UUID
        let favStrArr = favEfirs.map({ $0.name })
        UserDefaults.standard.set(favStrArr, forKey: favouritesKey)
        UserDefaults.standard.synchronize()
    }
        
    // Получение массива избранных названий станций из UserDefaults
    private func getFavourites() -> [MusicM] {
        let favStrArr = UserDefaults.standard.array(forKey: favouritesKey) as? [String] ?? []
        let efirsStrArr = self.efirs.map({ $0.name })
        let newFavStrArr = favStrArr.filter { efirsStrArr.contains($0) }
        let newfavArr = efirs.filter { newFavStrArr.contains($0.name) }
        self.favEfirs = newfavArr
        return newfavArr
    }
    
    func favAdd(efir: MusicM) {
        guard !favEfirs.contains(where: { $0 == efir }) else { return }
        favEfirs.append(efir)
        saveFavourites(favEfirs)
    }

    func favDel(efir: MusicM) {
        favEfirs.removeAll() { $0 == efir }
        saveFavourites(favEfirs)
    }
    
    // Проверка, в избранном ли станция
    func isFavorite(_ station: MusicM) -> Bool {
        favEfirs.contains(where: { $0.name == station.name })
    }
    // Добавить станцию в избранное
    func addToFavorites(_ station: MusicM) {
        if !isFavorite(station) {
            favEfirs.append(station)
            saveFavourites(favEfirs)
        }
    }
    // Удалить станцию из избранного
    func removeFromFavorites(_ station: MusicM) {
        favEfirs.removeAll(where: { $0.name == station.name })
        saveFavourites(favEfirs)
    }
    // Добавить в недавно прослушанные (ограничить 10)
    func addRecentlyPlayed(_ station: MusicM) {
        recentlyPlayed.removeAll(where: { $0.name == station.name })
        recentlyPlayed.insert(station, at: 0)
        if recentlyPlayed.count > 10 {
            recentlyPlayed.removeLast()
        }
    }
}

final class HomeVM: ObservableObject {
    @Published private(set) var headerStr = "Radios"
    @Published private(set) var playlists = [MusicM]()
    @Published var searchText: String = ""
    @Published private(set) var filteredPlaylists = [MusicM]()
    @Published private(set) var recentlyPlayed = [MusicM]()
    @Published var favorites: [MusicM] = []
    
    @Published private(set) var selectedMusic: MusicM? = nil
    @Published private(set) var selectedStationIndex: Int? = nil
    @Published private(set) var allStations: [MusicM] = []
    @Published var isLoading = true
    @Published var hasError = false
    
    var fetcher = RadioFetcher.shared
    @Published var displayPlayer = false
    
    private let maxRecentlyPlayedCount = 10
    private let recentlyPlayedKey = "recentlyPlayed"
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Don't load favorites/recent here - will load after fetcher completes

        // Subscribe to fetcher loading state
        fetcher.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)

        // Subscribe to fetcher updates so UI updates when network results arrive
        fetcher.$efirs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] efirs in
                guard let self = self else { return }
                self.playlists = efirs
                self.allStations = efirs
                // Load favorites and recent AFTER we have stations data
                self.loadFavorites()
                self.loadRecentlyPlayedFromStorage()
            }
            .store(in: &cancellables)

        // Keep recentlyPlayed in sync with fetcher
        fetcher.$recentlyPlayed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recent in
                self?.recentlyPlayed = recent
            }
            .store(in: &cancellables)
        
        // Observe changes to playlists and searchText with debounce
        $searchText
            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
            .combineLatest($playlists)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] searchText, playlists in
                guard let self = self else { return }
                if searchText.isEmpty {
                    self.filteredPlaylists = playlists
                } else {
                    self.filteredPlaylists = playlists.filter {
                        $0.name.localizedCaseInsensitiveContains(searchText)
                    }
                }
            }
            .store(in: &cancellables)
        
        // Sync favorites from fetcher to local favorites when fetcher updates
        fetcher.$favEfirs
            .receive(on: DispatchQueue.main)
            .sink { [weak self] favs in
                guard let self = self else { return }
                // Only update if we have stations loaded
                if !self.allStations.isEmpty {
                    self.favorites = favs
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchPlaylist() {
        playlists = fetcher.efirs
        allStations = fetcher.efirs
        
        // Refresh favorites after playlists update for consistency
        updateFavoritesFromFetcher()
    }
    
    func selectMusic(music: MusicM) {
        selectedMusic = music
        displayPlayer = true
        
        if let index = allStations.firstIndex(of: music) {
            selectedStationIndex = index
        } else {
            selectedStationIndex = nil
        }
        
        addToRecentlyPlayed(music)
    }
    
    // MARK: Recently Played
    
    func addToRecentlyPlayed(_ music: MusicM) {
        if let existingIndex = recentlyPlayed.firstIndex(of: music) {
            recentlyPlayed.remove(at: existingIndex)
        }
        recentlyPlayed.insert(music, at: 0)
        if recentlyPlayed.count > maxRecentlyPlayedCount {
            recentlyPlayed.removeLast()
        }
        saveRecentlyPlayed()
        fetcher.addRecentlyPlayed(music)
    }
    
    func clearRecentlyPlayed() {
        recentlyPlayed.removeAll()
        saveRecentlyPlayed()
        fetcher.recentlyPlayed.removeAll()
    }
    
    private func saveRecentlyPlayed() {
        let names = recentlyPlayed.map { $0.name }
        UserDefaults.standard.set(names, forKey: recentlyPlayedKey)
        UserDefaults.standard.synchronize()
    }
    
    private func loadRecentlyPlayed() {
        let savedNames = UserDefaults.standard.array(forKey: recentlyPlayedKey) as? [String] ?? []
        recentlyPlayed = [] // Will be populated by loadRecentlyPlayedFromStorage when fetcher completes
    }
    
    private func loadRecentlyPlayedFromStorage() {
        let savedNames = UserDefaults.standard.array(forKey: recentlyPlayedKey) as? [String] ?? []
        let loaded = allStations.filter { station in
            savedNames.contains(station.name)
        }
        // Restore order
        recentlyPlayed = savedNames.compactMap { name in
            loaded.first(where: { $0.name == name })
        }
    }
    
    // MARK: Favorites management
    
    func addToFavorites(_ music: MusicM) {
        guard !favorites.contains(where: { $0 == music }) else { return }
        favorites.append(music)
        fetcher.addToFavorites(music)
        saveFavorites()
    }
    
    func removeFromFavorites(_ music: MusicM) {
        favorites.removeAll(where: { $0 == music })
        fetcher.removeFromFavorites(music)
        saveFavorites()
    }

    // Toggle favorite state for a station
    func toggleFavorite(music: MusicM) {
        if favorites.contains(where: { $0 == music }) {
            removeFromFavorites(music)
        } else {
            addToFavorites(music)
        }
    }
    
    private func saveFavorites() {
        let favNames = favorites.map { $0.name }
        UserDefaults.standard.set(favNames, forKey: fetcher.favouritesKey)
        UserDefaults.standard.synchronize()
    }
    
    private func loadFavorites() {
        let favNames = UserDefaults.standard.array(forKey: fetcher.favouritesKey) as? [String] ?? []
        // Will be populated properly when allStations are loaded
        favorites = []
    }
    
    private func updateFavoritesFromFetcher() {
        // Sync favorites from fetcher
        favorites = fetcher.favEfirs
        
        // Also reload from UserDefaults to ensure persistence
        let savedFavNames = UserDefaults.standard.array(forKey: fetcher.favouritesKey) as? [String] ?? []
        let loadedFavorites = allStations.filter { station in
            savedFavNames.contains(station.name)
        }
        
        // Merge with fetcher favorites
        for fav in loadedFavorites {
            if !favorites.contains(where: { $0 == fav }) {
                favorites.append(fav)
            }
        }
        
        // Update fetcher to match
        fetcher.favEfirs = favorites
    }
}
