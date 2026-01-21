//
//  ContentView.swift
//  reversi
//
//  Created by dkqz on 21.01.2026.
//

import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState()
    @State private var aiPlayer: AIPlayer?
    @State private var isAIThinking = false
    @State private var showSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Заголовок и счет
            ScoreView(gameState: gameState)
            
            // Игровое поле
            BoardView(gameState: gameState, onCellTap: handleCellTap)
            
            HStack(spacing: 15) {
                // Кнопка новой игры
                Button("Новая игра") {
                    gameState.resetGame()
                    checkAITurn()
                }
                .buttonStyle(.borderedProminent)
                
                // Кнопка настроек
                Button("Настройки") {
                    showSettings = true
                }
                .buttonStyle(.bordered)
            }
            
            // Индикатор хода AI
            if isAIThinking {
                HStack {
                    ProgressView()
                        .progressViewStyle(.circular)
                    Text("AI думает...")
                        .font(.caption)
                }
            }
            
            // Диалог окончания игры
            if gameState.isGameOver {
                GameOverView(gameState: gameState)
            }
        }
        .padding()
        .sheet(isPresented: $showSettings) {
            SettingsView(gameState: gameState, isPresented: $showSettings)
        }
        .onAppear {
            // Проверяем, нужен ли AI ход при запуске
            checkAITurn()
        }
    }
    
    private func handleCellTap(row: Int, col: Int) {
        // Не разрешаем ход, если AI думает или игра окончена
        guard !isAIThinking, !gameState.isGameOver else { return }
        
        // Если режим игры с AI и сейчас ход AI - игнорируем клик
        if case .humanVsComputer = gameState.gameMode,
           gameState.currentPlayer == .white {
            return
        }
        
        let position = Position(row: row, col: col)
        if gameState.makeMove(position) {
            // После хода человека проверяем, не настал ли ход AI
            checkAITurn()
        }
    }
    
    private func checkAITurn() {
        // Проверяем, нужно ли AI сделать ход
        guard case .humanVsComputer(let difficulty) = gameState.gameMode,
              !gameState.isGameOver,
              gameState.currentPlayer == .white else {
            return
        }
        
        // Создаем AI если его еще нет или изменилась сложность
        if aiPlayer == nil || aiPlayer?.difficulty != difficulty {
            aiPlayer = AIPlayer(difficulty: difficulty)
        }
        
        // Запускаем ход AI с небольшой задержкой для естественности
        isAIThinking = true
        
        Task {
            // Небольшая задержка, чтобы игрок видел состояние поля
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 секунды
            
            await MainActor.run {
                if let move = aiPlayer?.chooseMove(gameState: gameState, player: .white) {
                    _ = gameState.makeMove(move)
                }
                isAIThinking = false
                
                // Рекурсивно проверяем, может AI нужен еще ход (если у человека нет ходов)
                checkAITurn()
            }
        }
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
                    .transition(.scale.combined(with: .opacity))
            } else if isValidMove {
                // Показываем подсказку для валидного хода
                Circle()
                    .stroke(Color.yellow.opacity(0.6), lineWidth: 2)
                    .padding(8)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: cellType)
        .animation(.easeInOut(duration: 0.2), value: isValidMove)
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

// MARK: - Settings View
struct SettingsView: View {
    let gameState: GameState
    @Binding var isPresented: Bool
    @State private var selectedMode: Int = 0
    @State private var selectedDifficulty: AIDifficulty = .beginner
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Режим игры")) {
                    Picker("Режим", selection: $selectedMode) {
                        Text("Человек vs Человек").tag(0)
                        Text("Человек vs Компьютер").tag(1)
                    }
                    .pickerStyle(.segmented)
                }
                
                if selectedMode == 1 {
                    Section(header: Text("Сложность AI")) {
                        Picker("Уровень", selection: $selectedDifficulty) {
                            Text("Новичок").tag(AIDifficulty.beginner)
                            Text("Профессионал").tag(AIDifficulty.professional)
                        }
                        .pickerStyle(.segmented)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            if selectedDifficulty == .beginner {
                                Text("Новичок выбирает ход по простой оценке")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Профессионал анализирует ответные ходы противника (глубина 2)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section {
                    Button("Применить и начать новую игру") {
                        applySettings()
                        isPresented = false
                    }
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        isPresented = false
                    }
                }
            }
            .onAppear {
                // Инициализируем текущие настройки
                switch gameState.gameMode {
                case .humanVsHuman:
                    selectedMode = 0
                case .humanVsComputer(let difficulty):
                    selectedMode = 1
                    selectedDifficulty = difficulty
                }
            }
        }
    }
    
    private func applySettings() {
        let newMode: GameMode
        if selectedMode == 0 {
            newMode = .humanVsHuman
        } else {
            newMode = .humanVsComputer(difficulty: selectedDifficulty)
        }
        
        gameState.setGameMode(newMode)
        gameState.resetGame()
    }
}

#Preview {
    ContentView()
}
