//
//  ReactionView.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import SwiftUI
import FirebaseAuth

struct ReactionView: View {
    let likes: [Id]
    let onImageTap: () -> Void
    let onTextTap: () -> Void
    
    var body: some View {
        let liked = likes.contains(where: { $0.id == Auth.auth().currentUser?.uid })
        
        HStack {
            Image(systemName: "hand.thumbsup\(liked ? ".fill" : "")")
                .foregroundColor(liked ? .pink : .secondary)
                .onTapGesture {apGesture in
                    onImageTap()
                }
            
            if likes.count > 0 {
                Text("\(likes.count)")
                    .fontWeight(.bold)
                    .font(.caption)
                    .onTapGesture {
                        onTextTap()
                    }
            }
        }
    }
}

#Preview {
    ReactionView(likes: [], onImageTap: {}, onTextTap: {})
}
