//
//  PlayerV.swift
//  RadioApp
//  Created by B.RF Group on 03.11.2025.
//
import SwiftUI

fileprivate let HORIZONTAL_SPACING: CGFloat = 24

struct PlayerV: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @StateObject var viewModel: PlayerVM
    @StateObject var radioPlayer: RadioPlayer
    
    @State private var stations: [MusicM]
    @State private var currentIndex: Int
    @State private var isBuffering = false
    
    init(viewModel: PlayerVM, stations: [MusicM], currentIndex: Int) {
        _viewModel = StateObject(wrappedValue: viewModel)
        _stations = State(initialValue: stations)
        _currentIndex = State(initialValue: currentIndex)
        _radioPlayer = StateObject(wrappedValue: RadioPlayer())
    }
    
    var body: some View {
        ZStack {
            Color.primary_color.edgesIgnoringSafeArea(.all)
            
            VStack(alignment: .center, spacing: 0) {
                HStack(alignment: .center) {
                    Button(action: { self.presentationMode.wrappedValue.dismiss() }) {
                        Image.close.resizable().frame(width: 20, height: 20)
                            .padding(8).background(Color.primary_color)
                            .cornerRadius(20).modifier(NeuShadow())
                    }
                    Spacer()
                    Button(action: {  }) {
                        Image.options.resizable().frame(width: 16, height: 16)
                            .padding(12).background(Color.primary_color)
                            .cornerRadius(20).modifier(NeuShadow())
                    }
                }.padding(.horizontal, HORIZONTAL_SPACING).padding(.top, 12)
                
                PlayerDiscV(coverImage: viewModel.model.imageUrl)
                
                Text(viewModel.model.name)
                    .foregroundColor(.text_header)
                    .font(.system(size: 20, weight: .bold))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 32)
                    .padding(.top, 12)
                
                Spacer()
                
                HStack(alignment: .center, spacing: 12) {
                    Text(viewModel.isPlaying ? "Live" : "Paused")
                        .foregroundColor(.text_primary)
                        .font(.system(size: 13, weight: .semibold))
                        .frame(width: 60, alignment: .leading)
                    
                    Slider(value: $radioPlayer.volume, in: 0...1)
                        .accentColor(.main_white)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                            toggleLike()
                        }
                    }) {
                        (viewModel.liked ? Image.heart_filled : Image.heart)
                            .resizable().frame(width: 22, height: 22)
                            .foregroundColor(viewModel.liked ? .red : .text_primary)
                    }
                }.padding(.horizontal, 45)
                
                Spacer()
                
                HStack(alignment: .center) {
                    Button(action: { previousStation() }) {
                        Image.next.resizable().frame(width: 18, height: 18)
                            .rotationEffect(Angle(degrees: 180))
                            .padding(24).background(Color.primary_color)
                            .cornerRadius(40).modifier(NeuShadow())
                    }
                    Spacer()
                    Button(action: { playPause(efir: viewModel.model) }) {
                        (viewModel.isPlaying ? Image.pause : Image.play)
                            .resizable().frame(width: 28, height: 28)
                            .padding(50).background(Color.main_color)
                            .cornerRadius(70).modifier(NeuShadow())
                    }
                    Spacer()
                    Button(action: { nextStation() }) {
                        Image.next.resizable().frame(width: 18, height: 18)
                            .padding(24).background(Color.primary_color)
                            .cornerRadius(40).modifier(NeuShadow())
                    }
                }.padding(.horizontal, 32)
            }.padding(.bottom, HORIZONTAL_SPACING)
            .animation(.spring(), value: viewModel.isPlaying)
            .onAppear {
                // Sync liked state with RadioFetcher
                viewModel.liked = RadioFetcher.shared.isFavorite(viewModel.model)
                // Ensure RadioPlayer knows the stations and current index
                radioPlayer.stations = stations
                radioPlayer.currentIndex = currentIndex
                // Start playing if not already
                if !radioPlayer.isPlaying || radioPlayer.efir != viewModel.model {
                    radioPlayer.play(viewModel.model)
                    viewModel.isPlaying = true
                    RadioFetcher.shared.addRecentlyPlayed(viewModel.model)
                }
            }
        }
    }
    
    private func playPause(efir: MusicM) {
        viewModel.isPlaying.toggle()
        if efir != radioPlayer.efir {
            radioPlayer.initPlayer(url: efir.streamUrl)
            radioPlayer.play(efir)
            RadioFetcher.shared.addRecentlyPlayed(efir)
            viewModel.liked = RadioFetcher.shared.isFavorite(efir)
            updateCurrentIndex(for: efir)
        } else if !radioPlayer.isPlaying {
            radioPlayer.play(efir)
            RadioFetcher.shared.addRecentlyPlayed(efir)
        } else {
            radioPlayer.stop()
        }
    }
    
    private func previousStation() {
        guard !stations.isEmpty else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentIndex = (currentIndex - 1 + stations.count) % stations.count
            changeStation(to: stations[currentIndex])
        }
    }
    
    private func nextStation() {
        guard !stations.isEmpty else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            currentIndex = (currentIndex + 1) % stations.count
            changeStation(to: stations[currentIndex])
        }
    }
    
    private func changeStation(to efir: MusicM) {
        viewModel.model = efir
        viewModel.isPlaying = true
        viewModel.liked = RadioFetcher.shared.isFavorite(efir)
        radioPlayer.initPlayer(url: efir.streamUrl)
        radioPlayer.play(efir)
        RadioFetcher.shared.addRecentlyPlayed(efir)
    }
    
    private func toggleLike() {
        if viewModel.liked {
            RadioFetcher.shared.removeFromFavorites(viewModel.model)
            viewModel.liked = false
        } else {
            RadioFetcher.shared.addToFavorites(viewModel.model)
            viewModel.liked = true
        }
    }
    
    private func updateCurrentIndex(for efir: MusicM) {
        if let idx = stations.firstIndex(where: { $0.id == efir.id }) {
            currentIndex = idx
        }
    }
}
