//
//  PlayerDiscV.swift
//  RadioApp
//  Created by B.RF Group on 03.11.2025.
//
import SwiftUI

struct PlayerDiscV: View {
    let coverImage: URL
    @State private var isRotating = false
    
    var body: some View {
        ZStack {
            Circle().foregroundColor(.primary_color)
                .frame(width: 300, height: 300).modifier(NeuShadow())
            
            ForEach(0..<15, id: \.self) { i in
                RoundedRectangle(cornerRadius: (150 + CGFloat((8 * i))) / 2)
                    .stroke(lineWidth: 0.25)
                    .foregroundColor(.disc_line)
                    .frame(width: 150 + CGFloat((8 * i)),
                           height: 150 + CGFloat((8 * i)))
            }
            
            AsyncImage(url: coverImage) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.primary_color.opacity(0.5), lineWidth: 3)
                        )
                } else if phase.error != nil {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 120, height: 120)
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 40))
                            .foregroundColor(.text_primary.opacity(0.5))
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 120, height: 120)
                        ProgressView()
                    }
                }
            }
        }
    }
}
