//
//  ContentView.swift
//  reversi
//
//  Created by dkqz on 21.01.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState()
    
    var body: some View {
        VStack(spacing: 20) {
            // Игровое поле
            BoardView(gameState: gameState)
        }
        .padding()
    }
}

// MARK: - Board View
struct BoardView: View {
    let gameState: GameState
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<8, id: \.self) { col in
                        CellView(cellType: gameState.board[row][col])
                    }
                }
            }
        }
        .background(Color.black)
        .padding(4)
    }
}

// MARK: - Cell View
struct CellView: View {
    let cellType: CellType
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.green.opacity(0.6))
                .aspectRatio(1, contentMode: .fit)
            
            if cellType != .empty {
                Circle()
                    .fill(cellType == .black ? Color.black : Color.white)
                    .padding(4)
                    .shadow(radius: 2)
            }
        }
    }
}

#Preview {
    ContentView()
}
