//
//  RatingView.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import SwiftUI

struct RatingView: View {
    @Binding var rating: Int
    
    var body: some View {
        HStack {
            ForEach(0..<5) { i in
                Image(systemName: i < rating ? "star.fill" : "star")
                    .onTapGesture {
                        rating = i + 1
                    }
                    .foregroundColor(i < rating ? .yellow : .secondary)
            }
        }
    }
}

#Preview {
    RatingView(rating: Binding(
        get: { 0 }, set: { _ in }
    ))
}
