//
//  HomeV.swift
//  RadioApp
//  Created by B.RF Group on 03.11.2025.
//
import SwiftUI

struct HomeV: View {
    @StateObject private var viewModel = HomeVM()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            Color.primary_color.edgesIgnoringSafeArea(.all)
            
            if viewModel.isLoading {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.text_primary)
                    Text("Загружаем станции...")
                        .foregroundColor(.text_primary)
                        .font(.headline)
                }
            } else {
                VStack(spacing: 0) {
                    // Header
                    HomeHeaderV(headerStr: viewModel.headerStr)
                    
                    // Search Field
                    TextField("Поиск станций...", text: $viewModel.searchText)
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(.horizontal, Constants.Sizes.HORIZONTAL_SPACING)
                        .padding(.top, 12)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    // Content based on selected tab
                    TabView(selection: $selectedTab) {
                        // All Stations
                        stationsList(playlists: viewModel.filteredPlaylists, title: "Все станции")
                            .tag(0)
                        
                        // Favorites (only show if not empty)
                        if !viewModel.favorites.isEmpty {
                            stationsList(playlists: viewModel.favorites, title: "Избранное")
                                .tag(1)
                        }
                        
                        // Recently Played (only show if not empty)
                        if !viewModel.recentlyPlayed.isEmpty {
                            stationsList(playlists: viewModel.recentlyPlayed, title: "Недавние")
                                .tag(2)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    
                    // Custom Tab Bar
                    CustomTabBar(
                        selectedTab: $selectedTab,
                        hasFavorites: !viewModel.favorites.isEmpty,
                        hasRecent: !viewModel.recentlyPlayed.isEmpty
                    )
                    .padding(.bottom, 8)
                }
                .fullScreenCover(isPresented: $viewModel.displayPlayer) {
                    if let model = viewModel.selectedMusic {
                        PlayerV(
                            viewModel: PlayerVM(model: model, stations: viewModel.allStations),
                            stations: viewModel.allStations,
                            currentIndex: viewModel.allStations.firstIndex(where: { $0 == model }) ?? 0
                        )
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func stationsList(playlists: [MusicM], title: String) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            if playlists.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 60))
                        .foregroundColor(.text_primary.opacity(0.5))
                        .padding(.top, 60)
                    Text(viewModel.searchText.isEmpty ? "Станции не найдены" : "Нет результатов")
                        .foregroundColor(.text_primary)
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 40)
            } else {
                HomePlaylistV(
                    playlists: playlists,
                    onSelect: { music in
                        viewModel.selectMusic(music: music)
                        viewModel.addToRecentlyPlayed(music)
                    },
                    onToggleFavorite: { music in
                        viewModel.toggleFavorite(music: music)
                    },
                    favEfirs: viewModel.favorites
                )
                .padding(.top, 16)
            }
        }
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    let hasFavorites: Bool
    let hasRecent: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            // All Stations Tab
            TabBarButton(
                icon: "list.bullet",
                title: "Все",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            // Favorites Tab (only if has favorites)
            if hasFavorites {
                TabBarButton(
                    icon: "heart.fill",
                    title: "Избранное",
                    isSelected: selectedTab == 1
                ) {
                    selectedTab = 1
                }
            }
            
            // Recently Played Tab (only if has recent)
            if hasRecent {
                TabBarButton(
                    icon: "clock.fill",
                    title: "Недавние",
                    isSelected: selectedTab == 2
                ) {
                    selectedTab = 2
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.primary_color)
                .modifier(NeuShadow())
        )
        .padding(.horizontal, Constants.Sizes.HORIZONTAL_SPACING)
    }
}

// MARK: - Tab Bar Button
struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .main_color : .text_primary.opacity(0.6))
                
                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .text_header : .text_primary.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.primary_color.opacity(0.5) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

fileprivate struct HomePlaylistV: View {
    let playlists: [MusicM]
    let onSelect: (MusicM) -> ()
    let onToggleFavorite: (MusicM) -> ()
    let favEfirs: [MusicM]

    var body: some View {
        LazyVStack(spacing: 16) {
            ForEach(playlists, id: \.id) { music in
                Button(action: {
                    onSelect(music)
                }, label: {
                    HStack(spacing: 16) {
                        AsyncImage(url: music.imageUrl) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } else if phase.error != nil {
                                Color.gray.opacity(0.3)
                                    .overlay(
                                        Image(systemName: "antenna.radiowaves.left.and.right")
                                            .foregroundColor(.text_primary.opacity(0.5))
                                    )
                            } else {
                                Color.gray.opacity(0.3)
                                    .overlay(ProgressView())
                            }
                        }
                        .frame(width: 60, height: 60)
                        .cornerRadius(12)
                        .modifier(NeuShadow())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(music.name)
                                .foregroundColor(.text_header)
                                .font(.system(size: 16, weight: .semibold))
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                            
                            Text("Radio Station")
                                .foregroundColor(.text_primary)
                                .font(.system(size: 13))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                onToggleFavorite(music)
                            }
                        }) {
                            Image(systemName: favEfirs.contains(where: { $0.id == music.id }) ? "heart.fill" : "heart")
                                .foregroundColor(favEfirs.contains(where: { $0.id == music.id }) ? .red : .text_primary)
                                .font(.system(size: 20))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(12)
                    .background(Color.primary_color)
                    .cornerRadius(16)
                    .modifier(NeuShadow())
                })
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, Constants.Sizes.HORIZONTAL_SPACING)
    }
}
