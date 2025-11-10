//
//  PlaylistV.swift
//  RadioApp
//  Created by B.RF Group on 03.11.2025.
//
import SwiftUI

struct PlaylistV: View {
    let name: String
    let coverImage: URL
    var isFavorite: Bool = false
    var onFavoriteTap: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: coverImage) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else {
                        Color.gray
                    }
                }
                .frame(width: 140, height: 100)
                .cornerRadius(16)
                
                if let onFavoriteTap = onFavoriteTap {
                    Button(action: onFavoriteTap) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .foregroundColor(isFavorite ? .red : .white)
                            .imageScale(.large)
                            .padding(8)
                            .background(Color.black.opacity(0.4))
                            .clipShape(Circle())
                    }
                    .padding(8)
                }
            }
            
            Text(name)
                .foregroundColor(.text_primary)
                .bold()
                .frame(height: 70)
                .padding(.top, 12)
                .padding(.bottom, 6)
        }
        .padding(12)
        .background(Color.primary_color)
        .cornerRadius(24).modifier(NeuShadow())
        .frame(maxWidth: 200, maxHeight: 400)
    }
}
