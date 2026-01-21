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
            // Заголовок и счет
            ScoreView(gameState: gameState)
            
            // Игровое поле
            BoardView(gameState: gameState, onCellTap: handleCellTap)
            
            // Кнопка новой игры
            Button("Новая игра") {
                gameState.resetGame()
            }
            .buttonStyle(.borderedProminent)
            
            // Диалог окончания игры
            if gameState.isGameOver {
                GameOverView(gameState: gameState)
            }
        }
        .padding()
    }
    
    private func handleCellTap(row: Int, col: Int) {
        let position = Position(row: row, col: col)
        _ = gameState.makeMove(position)
    }
}

// MARK: - Score View
struct ScoreView: View {
    let gameState: GameState
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Реверси")
                .font(.largeTitle)
                .bold()
            
            HStack(spacing: 40) {
                // Черные
                VStack {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 30, height: 30)
                    Text("\(gameState.blackCount)")
                        .font(.title2)
                        .bold()
                }
                .opacity(gameState.currentPlayer == .black ? 1.0 : 0.5)
                
                // Белые
                VStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 30, height: 30)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1))
                    Text("\(gameState.whiteCount)")
                        .font(.title2)
                        .bold()
                }
                .opacity(gameState.currentPlayer == .white ? 1.0 : 0.5)
            }
            
            Text("Ход: \(gameState.currentPlayer.name)")
                .font(.headline)
        }
    }
}

// MARK: - Board View
struct BoardView: View {
    let gameState: GameState
    let onCellTap: (Int, Int) -> Void
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<8, id: \.self) { col in
                        CellView(
                            cellType: gameState.board[row][col],
                            isValidMove: gameState.isValidMove(
                                Position(row: row, col: col),
                                for: gameState.currentPlayer
                            )
                        )
                        .onTapGesture {
                            onCellTap(row, col)
                        }
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
    let isValidMove: Bool
    
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
            } else if isValidMove {
                // Показываем подсказку для валидного хода
                Circle()
                    .stroke(Color.yellow, lineWidth: 2)
                    .padding(8)
            }
        }
    }
}

// MARK: - Game Over View
struct GameOverView: View {
    let gameState: GameState
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Игра окончена!")
                .font(.title)
                .bold()
            
            if let winner = gameState.winner {
                Text("Победили \(winner.name)!")
                    .font(.headline)
            } else {
                Text("Ничья!")
                    .font(.headline)
            }
            
            Text("Черные: \(gameState.blackCount)")
            Text("Белые: \(gameState.whiteCount)")
        }
        .padding()
        .background(Color.gray.opacity(0.2))
        .cornerRadius(10)
    }
}

#Preview {
    ContentView()
}
