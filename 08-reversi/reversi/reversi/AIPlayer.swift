//
//  AIPlayer.swift
//  reversi
//
//  Created by dkqz on 21.01.2026.
//

import Foundation

class AIPlayer {
    let difficulty: AIDifficulty
    
    init(difficulty: AIDifficulty) {
        self.difficulty = difficulty
    }
    
    // MARK: - Main AI Method
    
    /// Выбрать лучший ход для AI
    func chooseMove(gameState: GameState, player: Player) -> Position? {
        let validMoves = gameState.getValidMoves(for: player)
        
        guard !validMoves.isEmpty else {
            return nil
        }
        
        switch difficulty {
        case .beginner:
            return chooseBasicMove(gameState: gameState, player: player, validMoves: validMoves)
        case .professional:
            return chooseMoveAsProfessional(gameState: gameState, player: player, validMoves: validMoves)
        }
    }
    
    // MARK: - Basic AI Strategy
    
    /// Базовая стратегия: выбирает ход, максимизирующий оценочную функцию
    private func chooseBasicMove(gameState: GameState, player: Player, validMoves: [Position]) -> Position? {
        var bestMove: Position?
        var bestScore = -Double.infinity
        
        for move in validMoves {
            let score = evaluateMove(move, gameState: gameState, player: player, depth: 0)
            
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        
        return bestMove
    }
    
    /// Оценочная функция для базовой стратегии
    /// R(x,y) = Σ(si + ss)
    private func evaluateMove(_ position: Position, gameState: GameState, player: Player, depth: Int) -> Double {
        let flippedPieces = gameState.getFlippedPieces(position, for: player)
        
        // Если ход не захватывает фишки, он невалиден
        guard !flippedPieces.isEmpty else {
            return -Double.infinity
        }
        
        var score = 0.0
        
        // ss - ценность клетки, на которую совершается ход
        let ss = getCellValue(position)
        
        // Суммируем ценность захваченных фишек
        for piece in flippedPieces {
            let si = getFlippedCellValue(piece)
            score += si
        }
        
        // Добавляем ценность самой клетки
        score += ss
        
        return score
    }
    
    // MARK: - Helper Methods
    
    /// Получить ценность клетки для хода (ss)
    private func getCellValue(_ position: Position) -> Double {
        // Угловые клетки (самые ценные)
        if isCorner(position) {
            return 0.8
        }
        
        // Кромочные клетки
        if isEdge(position) {
            return 0.4
        }
        
        // Остальные клетки
        return 0.0
    }
    
    /// Получить ценность захваченной фишки (si)
    private func getFlippedCellValue(_ position: Position) -> Double {
        // Кромочная клетка (более ценная)
        if isEdge(position) {
            return 2.0
        }
        
        // Обычная клетка
        return 1.0
    }
    
    /// Проверить, является ли клетка угловой
    private func isCorner(_ position: Position) -> Bool {
        let corners: [(Int, Int)] = [(0, 0), (0, 7), (7, 0), (7, 7)]
        return corners.contains { $0.0 == position.row && $0.1 == position.col }
    }
    
    /// Проверить, является ли клетка кромочной (на краю доски)
    private func isEdge(_ position: Position) -> Bool {
        return position.row == 0 || position.row == 7 || 
               position.col == 0 || position.col == 7
    }
    
    // MARK: - Professional AI (Level 2)
    
    /// Профессионал: анализирует ответные ходы противника (глубина 2)
    private func chooseMoveAsProfessional(gameState: GameState, player: Player, validMoves: [Position]) -> Position? {
        var bestMove: Position?
        var bestScore = -Double.infinity
        
        for move in validMoves {
            let score = evaluateMoveProfessional(move, gameState: gameState, player: player)
            
            if score > bestScore {
                bestScore = score
                bestMove = move
            }
        }
        
        return bestMove
    }
    
    /// Оценочная функция для профессионала с анализом ответа противника
    /// R(x,y, dep=0) = Σ(si + ss) - max(R(x1,y1, dep=1))
    private func evaluateMoveProfessional(_ position: Position, gameState: GameState, player: Player) -> Double {
        // Создаем копию состояния игры для симуляции
        let simulatedState = copyGameState(gameState)
        
        // Симулируем ход компьютера
        let flippedPieces = simulatedState.getFlippedPieces(position, for: player)
        
        guard !flippedPieces.isEmpty else {
            return -Double.infinity
        }
        
        // Применяем ход
        simulatedState.setCell(position, to: player.cellType)
        for piece in flippedPieces {
            simulatedState.setCell(piece, to: player.cellType)
        }
        
        // Вычисляем выигрыш от этого хода (dep=0)
        var myScore = 0.0
        let ss = getCellValue(position)
        for piece in flippedPieces {
            let si = getFlippedCellValue(piece)
            myScore += si
        }
        myScore += ss
        
        // Теперь анализируем лучший ответ противника (dep=1)
        let opponent = player.opposite
        let opponentMoves = simulatedState.getValidMoves(for: opponent)
        
        var opponentBestScore = 0.0
        
        if !opponentMoves.isEmpty {
            // Находим лучший ход противника
            for opponentMove in opponentMoves {
                let opponentFlipped = simulatedState.getFlippedPieces(opponentMove, for: opponent)
                
                var opponentScore = 0.0
                let opponentSs = getCellValue(opponentMove)
                for piece in opponentFlipped {
                    let si = getFlippedCellValue(piece)
                    opponentScore += si
                }
                opponentScore += opponentSs
                
                if opponentScore > opponentBestScore {
                    opponentBestScore = opponentScore
                }
            }
        }
        
        // Итоговая оценка: наш выигрыш минус лучший ответ противника
        return myScore - opponentBestScore
    }
    
    /// Создать копию состояния игры для симуляции
    private func copyGameState(_ gameState: GameState) -> GameState {
        let copy = GameState(gameMode: gameState.gameMode)
        
        // Копируем доску
        for row in 0..<8 {
            for col in 0..<8 {
                let pos = Position(row: row, col: col)
                copy.setCell(pos, to: gameState.cellAt(pos))
            }
        }
        
        return copy
    }
}
