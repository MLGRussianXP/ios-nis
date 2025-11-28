//
//  HeaderView.swift
//  Recipes
//
//  Created by dkqz on 27.11.2025.
//

import SwiftUI

struct HeaderView: View {
    let title: String
    let subtitle: String
    let angle: Double
    let background: Color
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(background)
                .rotationEffect(.degrees(angle))
                .frame(width: UIScreen.main.bounds.width * 3, height: 370)
            
            VStack {
                Text(title)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .bold()
                Text(subtitle)
                    .font(.system(size: 25))
                    .foregroundColor(.white)
            }
            .padding(.top, 100)
        }
        .offset(y: -140)
    }
}

#Preview {
    HeaderView(
        title: "Title",
        subtitle: "Subtitle",
        angle: 15,
        background: .accentColor
    )
}
